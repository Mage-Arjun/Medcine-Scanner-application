import asyncio
import os
import httpx
import pandas as pd
from bs4 import BeautifulSoup

OUTPUT_FILE = "medicine_details_full.csv"

# Replace these with your 35 URLs
URLS = [
    "https://www.1mg.com/drugs/alnacet-5mg-tablet-391297",
"https://www.1mg.com/drugs/amlyzo-es-30mg-40mg-capsule-522763",
"https://www.1mg.com/drugs/amlyzo-r-30mg-20mg-capsule-696018",
"https://www.1mg.com/drugs/axifer-100mg-injection-412710",
"https://www.1mg.com/drugs/azomentin-500-mg-125-mg-tablet-248119",
"https://www.1mg.com/drugs/demo-p-50-mg-500-mg-tablet-235900",
"https://www.1mg.com/drugs/demo-s-50-mg-10-mg-tablet-263320",
"https://www.1mg.com/drugs/evaclav-500mg-125mg-tablet-493996",
"https://www.1mg.com/drugs/glimozen-mp1-tablet-er-1003673",
"https://www.1mg.com/drugs/inflazen-forte-tablet-238940",
"https://www.1mg.com/drugs/inmax-10mg-tablet-505019",
"https://www.1mg.com/drugs/jakavi-15mg-tablet-334561",
"https://www.1mg.com/drugs/kacizone-500mg-injection-767327",
"https://www.1mg.com/drugs/nadix-1-cream-414880",
"https://www.1mg.com/drugs/norex-0.25mg-tablet-268718",
"https://www.1mg.com/drugs/oflo-50mg-5ml-suspension-288388",
"https://www.1mg.com/drugs/oflo-oz-suspension-430249",
"https://www.1mg.com/drugs/peetam-500mg-tablet-696060",
"https://www.1mg.com/drugs/podomed-200mg-tablet-785263",
"https://www.1mg.com/drugs/podomed-50mg-dry-syrup-787065",
"https://www.1mg.com/drugs/poped-10mg-40mg-tablet-696123",
"https://www.1mg.com/drugs/raxicef-cv-200mg-125mg-tablet-1085787",
"https://www.1mg.com/drugs/rebitage-d-30mg-20mg-capsule-sr-522880",
"https://www.1mg.com/drugs/semolid-100mg-tablet-1064315",
"https://www.1mg.com/drugs/sepa-10mg-tablet-771793",
"https://www.1mg.com/drugs/spido-100mg-dry-syrup-696134",
"https://www.1mg.com/drugs/suclice-o-oral-suspension-604912",
"https://www.1mg.com/drugs/texof-mx-10mg-180mg-tablet-909516",
"https://www.1mg.com/drugs/ulcecure-gel-314293",
"https://www.1mg.com/drugs/vilfree-m-0.5mg-10mg-tablet-854594",
"https://www.1mg.com/drugs/vindcef-50-dry-syrup-704519",
"https://www.1mg.com/drugs/xeetam-cv-250mg-125mg-tablet-696152",
"https://www.1mg.com/drugs/zienam-500mg-500mg-injection-165246",
"https://www.1mg.com/drugs/zuche-lidocaine-hydrochloride-oral-topical-solution-1143156",
"https://www.1mg.com/drugs/zyro-500mg-tablet-332214",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


def clean_text(text):
    if not text:
        return None
    skip = {"USES OF", "BENEFITS OF", "SIDE EFFECTS OF"}
    seen, cleaned = set(), []
    for line in text.split("\n"):
        line = line.strip()
        if any(kw in line for kw in skip):
            continue
        if line not in seen and len(line) > 3:
            seen.add(line)
            cleaned.append(line)
    return " ".join(cleaned) or None


def parse_page(url, html):
    soup = BeautifulSoup(html, "lxml")

    name = soup.find("h1")
    name = name.text.strip() if name else None

    def get_after_label(label):
        tag = soup.find(lambda t: t.name == "div" and t.get_text(strip=True) == label)
        if tag:
            sibling = tag.find_next_sibling("div")
            if sibling:
                a = sibling.find("a")
                return a.text.strip() if a else sibling.get_text(strip=True)
        return None

    def extract_section(section_id):
        section = soup.find(id=section_id)
        if not section:
            return None
        content = section.find(class_=lambda c: c and "content" in c)
        return clean_text((content or section).get_text("\n"))

    img = soup.find("img", src=lambda s: s and "onemg" in s)

    return {
        "url": url,
        "name": name,
        "marketer": get_after_label("MARKETER"),
        "composition": get_after_label("SALT COMPOSITION"),
        "uses": extract_section("uses_and_benefits"),
        "side_effects": extract_section("side_effects"),
        "image_url": img["src"] if img else None,
    }


async def fetch(client, sem, url):
    async with sem:
        for attempt in range(3):
            try:
                r = await client.get(url, timeout=20)
                if r.status_code == 200:
                    return parse_page(url, r.text)
                elif r.status_code == 429:
                    await asyncio.sleep(2 ** attempt)
                else:
                    return {"url": url, "error": f"HTTP {r.status_code}"}
            except Exception:
                await asyncio.sleep(1)
        return {"url": url, "error": "Failed after 3 retries"}


def save_results(results):
    success = [r for r in results if not r.get("error")]
    failed  = [r for r in results if r.get("error")]

    if success:
        df = pd.DataFrame(success)
        write_header = not os.path.exists(OUTPUT_FILE)
        df.to_csv(OUTPUT_FILE, mode="a", header=write_header, index=False)
        print(f"\n✅ Saved {len(success)} rows to {OUTPUT_FILE}")
    else:
        print("\n⚠ No successful results to save.")

    if failed:
        print(f"\n❌ Failed ({len(failed)}):")
        for r in failed:
            print(f"   {r['url']} — {r['error']}")


async def main():
    sem = asyncio.Semaphore(4)
    async with httpx.AsyncClient(headers=HEADERS, follow_redirects=True) as client:
        results = await asyncio.gather(*[fetch(client, sem, url) for url in URLS])

    for r in results:
        print(f"\n{'='*60}")
        print(f"URL        : {r['url']}")
        if r.get("error"):
            print(f"ERROR      : {r['error']}")
            continue
        print(f"Name       : {r['name']}")
        print(f"Marketer   : {r['marketer']}")
        print(f"Composition: {r['composition']}")
        print(f"Uses       : {str(r['uses'])[:150]}")
        print(f"Side FX    : {str(r['side_effects'])[:150]}")
        print(f"Image      : {r['image_url']}")

    save_results(results)


if __name__ == "__main__":
    asyncio.run(main())
