"""
fix_images.py — Batch re-scrape correct product images from 1mg pages.

Optimizations over medinfo10x.py:
  1. Regex extraction instead of BeautifulSoup (10-50x faster parsing)
  2. Connection pooling + async concurrency (150 parallel requests)
  3. Only extracts image URL — single regex per page

Usage:
  python pipeline/fix_images.py                          # full run
  python pipeline/fix_images.py --batch-size 5000        # process 5000 at a time
  python pipeline/fix_images.py --resume                 # continue from last checkpoint
  python pipeline/fix_images.py --dry-run                # preview without writing
  python pipeline/fix_images.py --concurrency 200        # override concurrency
"""

import asyncio
import argparse
import json
import os
import re
import sys
import time
import random
from pathlib import Path

import httpx
import pandas as pd

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "final"
INPUT_CSV = DATA_DIR / "medicine_ready_v2.csv"
CHECKPOINT_DIR = PROJECT_ROOT / "pipeline" / "checkpoints"
LOG_FILE = PROJECT_ROOT / "pipeline" / "image_scrape_log.csv"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

# Regex patterns — these are the core optimization
# Matches: <link rel="preload" as="image" href="...">
PRELOAD_RE = re.compile(
    r'<link\s+rel="preload"\s+as="image"\s+href="'
    r'(https://onemg\.gumlet\.io/[^"]+)"',
    re.IGNORECASE,
)
# Fallback: <meta property="og:image" content="...">
OG_IMAGE_RE = re.compile(
    r'<meta\s+property="og:image"\s+content="(https?://[^"]+)"',
    re.IGNORECASE,
)

# The generic placeholder URL that we want to replace
PLACEHOLDER_URL = "iw8eipowl2ubpml6moi3.png"

PLACEHOLDER_PATTERNS = [
    "iw8eipowl2ubpml6moi3.png",
    "onemg.gumlet.io/q_auto,f_auto/iw8eipowl2ubpml6moi3",
]


def is_placeholder(url: str) -> bool:
    """Check if a URL is the known generic placeholder."""
    if not url or not isinstance(url, str):
        return True
    return any(p in url for p in PLACEHOLDER_PATTERNS)


# ---------------------------------------------------------------------------
# Checkpoint management
# ---------------------------------------------------------------------------

def ensure_checkpoint_dir():
    CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)


def checkpoint_path(batch_index: int) -> Path:
    return CHECKPOINT_DIR / f"images_batch_{batch_index}.json"


def save_checkpoint(batch_index: int, updates: dict):
    """Save a batch of {row_index: new_image_url} mappings."""
    path = checkpoint_path(batch_index)
    with open(path, "w") as f:
        json.dump(updates, f)
    print(f"  [checkpoint] Saved: {path.name} ({len(updates)} updates)")


def load_all_checkpoints() -> dict:
    """Load all checkpoints and return merged {row_index: new_image_url}."""
    all_updates = {}
    if not CHECKPOINT_DIR.exists():
        return all_updates
    for path in sorted(CHECKPOINT_DIR.glob("images_batch_*.json")):
        with open(path) as f:
            batch = json.load(f)
            all_updates.update(batch)
    return all_updates


# ---------------------------------------------------------------------------
# Fast image extraction using regex
# ---------------------------------------------------------------------------

def extract_image_from_html(html: str) -> str | None:
    """
    Extract the real product image URL from raw HTML using regex.
    Priority:
      1. <link rel="preload" as="image" href="..."> (fastest, most reliable)
      2. <meta property="og:image" content="...">
    Returns None if only placeholder found.
    """
    # Try preload link first (in <head>, usually in first 2KB)
    match = PRELOAD_RE.search(html)
    if match:
        url = match.group(1)
        if not is_placeholder(url):
            return url

    # Fallback to og:image
    match = OG_IMAGE_RE.search(html)
    if match:
        url = match.group(1)
        if not is_placeholder(url):
            return url

    return None


# ---------------------------------------------------------------------------
# Async fetcher
# ---------------------------------------------------------------------------

async def fetch_image_url(
    client: httpx.AsyncClient,
    sem: asyncio.Semaphore,
    url: str,
    retries: int = 3,
) -> str | None:
    """Fetch a 1mg page and extract the real product image URL."""
    async with sem:
        for attempt in range(retries):
            try:
                resp = await client.get(url, timeout=15)
                if resp.status_code in (200, 206):
                    return extract_image_from_html(resp.text)
                elif resp.status_code == 429:
                    # Rate limited — back off
                    wait = (2 ** attempt) + random.uniform(0, 1)
                    await asyncio.sleep(wait)
                elif resp.status_code in (403, 404, 503):
                    # Permanent failures — don't retry
                    return None
                else:
                    # Other errors — retry
                    await asyncio.sleep(1)
            except (httpx.TimeoutException, httpx.ConnectError, httpx.ReadError):
                await asyncio.sleep(1 + attempt)
            except Exception:
                await asyncio.sleep(1)
        return None


# ---------------------------------------------------------------------------
# Async writer with batching
# ---------------------------------------------------------------------------

async def writer_task(
    queue: asyncio.Queue,
    total_rows: int,
    dry_run: bool,
):
    """Consume results from queue and save checkpoints periodically."""
    batch_updates = {}
    batch_count = 0
    checkpoint_every = 1000
    saved_count = 0

    while True:
        item = await queue.get()
        if item is None:
            break

        row_idx, new_url = item
        if new_url is not None:
            batch_updates[str(row_idx)] = new_url
            saved_count += 1

        # Save checkpoint every N updates
        if len(batch_updates) >= checkpoint_every:
            batch_count += 1
            if not dry_run:
                save_checkpoint(batch_count, batch_updates)
            batch_updates = {}

    # Flush remaining
    if batch_updates:
        batch_count += 1
        if not dry_run:
            save_checkpoint(batch_count, batch_updates)

    return saved_count


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

async def run(args):
    print("=" * 60)
    print("  MediCam Image URL Fixer")
    print("  Optimized batch re-scrape from 1mg pages")
    print("=" * 60)
    print()

    # Load CSV
    print(f"[loading] {INPUT_CSV.name}...")
    df = pd.read_csv(INPUT_CSV)
    total_rows = len(df)
    print(f"   Total rows: {total_rows:,}")

    # Filter rows that need fixing (have a url but bad/missing image_url)
    needs_fix = []
    for idx, row in df.iterrows():
        url = row.get("url")
        img = row.get("image_url")
        if pd.isna(url) or not isinstance(url, str) or not url.startswith("http"):
            continue
        # Only fix rows with placeholder or missing image
        if pd.isna(img) or is_placeholder(str(img)):
            needs_fix.append(idx)

    print(f"   Rows needing fix: {len(needs_fix):,}")
    print(f"   Rows already OK:  {total_rows - len(needs_fix):,}")

    # Apply existing checkpoints
    if args.resume:
        checkpoints = load_all_checkpoints()
        print(f"   Checkpoints found: {len(checkpoints):,} updates")

        # Filter out already-fixed rows
        already_fixed = set()
        for idx_str, new_url in checkpoints.items():
            idx = int(idx_str)
            if idx in needs_fix:
                df.at[idx, "image_url"] = new_url
                already_fixed.add(idx)

        needs_fix = [i for i in needs_fix if i not in already_fixed]
        print(f"   After applying checkpoints: {len(needs_fix):,} remaining")

    if not needs_fix:
        print("\n[OK] All rows already have correct image URLs!")
        return

    # Apply batch limit
    if args.batch_size:
        needs_fix = needs_fix[: args.batch_size]
        print(f"   Batch limited to: {len(needs_fix):,} rows")

    # Build URL list
    urls = [(idx, df.at[idx, "url"]) for idx in needs_fix]
    print(f"\n[start] Scraping {len(urls):,} URLs")
    print(f"   Concurrency: {args.concurrency}")
    print(f"   Dry run: {args.dry_run}")
    print()

    ensure_checkpoint_dir()

    sem = asyncio.Semaphore(args.concurrency)
    write_queue = asyncio.Queue()
    success_count = 0
    fail_count = 0

    t_start = time.time()

    # Check HTTP/2 availability
    try:
        import h2  # noqa: F401
        use_http2 = True
        print("   HTTP/2: enabled")
    except ImportError:
        use_http2 = False
        print("   HTTP/2: disabled (install with pip install httpx[http2] for faster connections)")

    # Connection pool
    limits = httpx.Limits(
        max_connections=args.concurrency + 10,
        max_keepalive_connections=30,
        keepalive_expiry=30,
    )

    async with httpx.AsyncClient(
        headers=HEADERS,
        follow_redirects=True,
        http2=use_http2,
        limits=limits,
    ) as client:
        # Start writer task
        writer = asyncio.create_task(
            writer_task(write_queue, len(urls), args.dry_run)
        )

        # Launch all fetch tasks
        tasks = []
        for row_idx, url in urls:
            task = asyncio.create_task(fetch_image_url(client, sem, url))
            tasks.append((row_idx, task))

        # Process results as they complete
        completed = 0
        for row_idx, task in tasks:
            new_url = await task
            completed += 1

            if new_url:
                success_count += 1
                await write_queue.put((row_idx, new_url))
                if not args.dry_run:
                    df.at[row_idx, "image_url"] = new_url
            else:
                fail_count += 1

            # Progress update every 100 rows
            if completed % 100 == 0:
                elapsed = time.time() - t_start
                rate = completed / elapsed if elapsed > 0 else 0
                eta = (len(urls) - completed) / rate if rate > 0 else 0
                pct = completed / len(urls) * 100
                print(
                    f"  [{completed:>6}/{len(urls)}] "
                    f"{pct:5.1f}% | "
                    f"{success_count:>5} ok | "
                    f"{fail_count:>5} fail | "
                    f"{rate:.0f}/s | "
                    f"ETA {int(eta // 60)}m{int(eta % 60)}s"
                )

        # Signal writer to finish
        await write_queue.put(None)
        await writer

    elapsed = time.time() - t_start
    print()
    print("=" * 60)
    print(f"  Completed in {int(elapsed // 60)}m {int(elapsed % 60)}s")
    print(f"  Success: {success_count:,} | Failed: {fail_count:,}")
    print(f"  Rate: {success_count / elapsed:.1f} URLs/sec" if elapsed > 0 else "")

    # Save updated CSV
    if not args.dry_run and success_count > 0:
        print(f"\n[saving] Updated CSV...")
        df.to_csv(INPUT_CSV, index=False)
        print(f"   Saved to {INPUT_CSV}")
    elif args.dry_run:
        print(f"\n[dry-run] No changes written")

    # Save log
    log_entries = []
    for row_idx, url in urls:
        img = df.at[row_idx, "image_url"]
        log_entries.append({
            "row_index": row_idx,
            "url": url,
            "new_image_url": img if not is_placeholder(str(img)) else None,
            "status": "fixed" if not is_placeholder(str(img)) else "failed",
        })
    log_df = pd.DataFrame(log_entries)
    log_df.to_csv(LOG_FILE, index=False)
    print(f"[log] Saved to {LOG_FILE.name}")

    print()


def main():
    parser = argparse.ArgumentParser(
        description="Fix medicine image URLs by re-scraping from 1mg pages"
    )
    parser.add_argument(
        "--batch-size", type=int, default=None,
        help="Process only N rows (for testing)"
    )
    parser.add_argument(
        "--resume", action="store_true",
        help="Resume from last checkpoint"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Preview without writing changes"
    )
    parser.add_argument(
        "--concurrency", type=int, default=150,
        help="Number of parallel requests (default: 150)"
    )
    args = parser.parse_args()
    asyncio.run(run(args))


if __name__ == "__main__":
    main()
