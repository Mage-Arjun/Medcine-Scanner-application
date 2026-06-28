"""
verify_images.py — Validate medicine image URLs after batch re-scrape.

Samples random rows from the CSV, HEAD-requests each image_url,
and reports success rate and broken URLs.

Usage:
  python pipeline/verify_images.py                    # sample 100 random rows
  python pipeline/verify_images.py --sample 500       # sample 500 rows
  python pipeline/verify_images.py --all              # check ALL rows (slow)
  python pipeline/verify_images.py --concurrency 100  # parallel HEAD requests
"""

import asyncio
import argparse
import random
import time
from pathlib import Path

import httpx
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "final"
INPUT_CSV = DATA_DIR / "medicine_ready_v2.csv"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
}

PLACEHOLDER_PATTERNS = [
    "iw8eipowl2ubpml6moi3.png",
    "onemg.gumlet.io/q_auto,f_auto/iw8eipowl2ubpml6moi3",
]


def is_placeholder(url: str) -> bool:
    if not url or not isinstance(url, str):
        return True
    return any(p in url for p in PLACEHOLDER_PATTERNS)


async def check_url(
    client: httpx.AsyncClient,
    sem: asyncio.Semaphore,
    idx: int,
    url: str,
) -> dict:
    """HEAD-request an image URL and return status."""
    async with sem:
        try:
            resp = await client.head(url, timeout=10, follow_redirects=True)
            return {
                "index": idx,
                "url": url,
                "status": resp.status_code,
                "ok": resp.status_code == 200,
                "content_type": resp.headers.get("content-type", ""),
            }
        except Exception as e:
            return {
                "index": idx,
                "url": url,
                "status": 0,
                "ok": False,
                "error": str(e),
            }


async def run(args):
    print("=" * 60)
    print("  MediCam Image URL Verifier")
    print("=" * 60)
    print()

    # Load CSV
    print(f"[loading] {INPUT_CSV.name}...")
    df = pd.read_csv(INPUT_CSV)
    total = len(df)
    print(f"   Total rows: {total:,}")

    # Get rows with image URLs
    has_url = df[df["image_url"].notna() & (df["image_url"] != "")]
    print(f"   Rows with image_url: {len(has_url):,}")

    # Filter out placeholders
    real_images = has_url[~has_url["image_url"].apply(is_placeholder)]
    placeholders = has_url[has_url["image_url"].apply(is_placeholder)]
    print(f"   Real image URLs: {len(real_images):,}")
    print(f"   Placeholder URLs: {len(placeholders):,}")

    # Sample
    if args.all:
        sample = real_images
        print(f"\n[check] Checking ALL {len(sample):,} real image URLs...")
    else:
        sample_size = min(args.sample, len(real_images))
        sample = real_images.sample(n=sample_size, random_state=42)
        print(f"\n[check] Sampling {sample_size:,} random real image URLs...")

    if len(sample) == 0:
        print("\n⚠️  No real image URLs to verify. Run fix_images.py first.")
        return

    # Check URLs
    sem = asyncio.Semaphore(args.concurrency)
    results = []
    t_start = time.time()

    limits = httpx.Limits(
        max_connections=args.concurrency + 10,
        max_keepalive_connections=30,
    )

    async with httpx.AsyncClient(
        headers=HEADERS,
        follow_redirects=True,
        limits=limits,
    ) as client:
        tasks = [
            check_url(client, sem, idx, row["image_url"])
            for idx, row in sample.iterrows()
        ]

        completed = 0
        for coro in asyncio.as_completed(tasks):
            result = await coro
            results.append(result)
            completed += 1
            if completed % 50 == 0:
                elapsed = time.time() - t_start
                print(f"  [{completed}/{len(tasks)}] checked...")

    elapsed = time.time() - t_start

    # Analyze results
    ok_count = sum(1 for r in results if r["ok"])
    fail_count = len(results) - ok_count
    broken = [r for r in results if not r["ok"]]

    print()
    print("=" * 60)
    print(f"  Results ({elapsed:.1f}s)")
    print("=" * 60)
    print(f"  Total checked:  {len(results):,}")
    print(f"  [OK]   (200):    {ok_count:,} ({ok_count/len(results)*100:.1f}%)")
    print(f"  [FAIL] Broken:   {fail_count:,} ({fail_count/len(results)*100:.1f}%)")

    if broken:
        print(f"\n  Broken URLs (first 10):")
        for r in broken[:10]:
            err = r.get("error", f"HTTP {r['status']}")
            print(f"    {r['url'][:70]}... → {err}")

    # Estimate total broken
    if not args.all and len(placeholders) > 0:
        est_broken = int(fail_count / len(results) * len(real_images))
        print(f"\n  [stats] Estimated broken in full dataset: ~{est_broken:,}")

    print()


def main():
    parser = argparse.ArgumentParser(
        description="Verify medicine image URLs"
    )
    parser.add_argument(
        "--sample", type=int, default=100,
        help="Number of random rows to sample (default: 100)"
    )
    parser.add_argument(
        "--all", action="store_true",
        help="Check ALL rows (slow for large datasets)"
    )
    parser.add_argument(
        "--concurrency", type=int, default=100,
        help="Number of parallel HEAD requests (default: 100)"
    )
    args = parser.parse_args()
    asyncio.run(run(args))


if __name__ == "__main__":
    main()
