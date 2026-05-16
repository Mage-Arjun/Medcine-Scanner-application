import pandas as pd
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed

INPUT_FILE = "marketers.csv"
OUTPUT_FILE = "medicine_urls_full.csv"

HEADERS = {
    "User-Agent": "Mozilla/5.0"
}

session = requests.Session()
session.headers.update(HEADERS)


# ---------------------------
# EXTRACT MEDICINES
# ---------------------------
def extract_medicines(html):
    soup = BeautifulSoup(html, "lxml")

    meds = []

    for a in soup.select("a[href*='/drugs/'], a[href*='/otc/']"):
        href = a.get("href")
        name = a.get_text(strip=True)

        if href and name and len(name) > 2:
            meds.append({
                "medicine_name": name,
                "medicine_url": "https://www.1mg.com" + href
            })

    return meds


# ---------------------------
# SCRAPE ONE MARKETER (FIXED PAGINATION)
# ---------------------------
def scrape_marketer(row):
    marketer_name = row["name"]
    base_url = row["url"]

    all_meds = []
    page = 1
    prev_urls = set()

    while True:
        url = f"{base_url}?page={page}"

        try:
            r = session.get(url, timeout=15)

            if r.status_code != 200:
                break

            meds = extract_medicines(r.text)

            if not meds:
                break

            current_urls = set(m["medicine_url"] for m in meds)

            # 🔴 STOP if page repeats
            if current_urls == prev_urls:
                print(f"{marketer_name} → duplicate page detected at {page}, stopping")
                break

            # 🔴 STOP if very small page (end signal)
            if len(current_urls - prev_urls) == 0:
                print(f"{marketer_name} → no new medicines at page {page}, stopping")
                break

            prev_urls = current_urls

            all_meds.extend([
                {"marketer": marketer_name, **m}
                for m in meds
            ])

            print(f"{marketer_name} → page {page}: {len(meds)}")

            page += 1

            # 🔴 HARD SAFETY LIMIT
            if page > 100:
                print(f"{marketer_name} → hit page limit, stopping")
                break

        except Exception as e:
            print(f"Error {marketer_name}: {e}")
            break

    return all_meds


# ---------------------------
# PARALLEL RUNNER
# ---------------------------
def run_fast(workers=10):
    df = pd.read_csv(INPUT_FILE)

    all_data = []
    seen = set()

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(scrape_marketer, row) for _, row in df.iterrows()]

        for i, future in enumerate(as_completed(futures)):
            results = future.result()

            for item in results:
                if item["medicine_url"] not in seen:
                    seen.add(item["medicine_url"])
                    all_data.append(item)

            if i % 10 == 0:
                print(f"Processed {i}/{len(df)} marketers")
                pd.DataFrame(all_data).to_csv(OUTPUT_FILE, index=False)

    pd.DataFrame(all_data).to_csv(OUTPUT_FILE, index=False)

    print(f"\nDONE ✔ Total medicines: {len(all_data)}")


if __name__ == "__main__":
    run_fast(workers=10)