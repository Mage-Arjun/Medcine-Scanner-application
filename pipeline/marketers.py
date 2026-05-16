import time
import pandas as pd

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager


# ---------------------------
# CONFIG
# ---------------------------
BASE_URL = "https://www.1mg.com/marketers?pageName={}"
OUTPUT_FILE = "marketers_clean.csv"


# ---------------------------
# DRIVER SETUP
# ---------------------------
def create_driver():
    options = webdriver.ChromeOptions()

    # ❌ DO NOT use headless (important)
    # options.add_argument("--headless=new")

    options.add_argument("--start-maximized")
    options.add_argument("--disable-blink-features=AutomationControlled")

    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options
    )

    # remove automation flag
    driver.execute_script(
        "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
    )

    return driver


# ---------------------------
# SCRAPER
# ---------------------------
def scrape_marketers(max_pages=450):
    driver = create_driver()
    wait = WebDriverWait(driver, 20)

    all_data = []
    seen = set()

    for page in range(1, max_pages + 1):
        url = BASE_URL.format(page)
        print(f"\nScraping page {page}")

        driver.get(url)

        try:
            # ✅ wait for ANY marketer link (robust)
            wait.until(
                EC.presence_of_all_elements_located(
                    (By.CSS_SELECTOR, "a[href*='/marketer/']")
                )
            )
        except:
            print("No data found → stopping")
            break

        # scroll once to ensure load
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(1)

        links = driver.find_elements(By.CSS_SELECTOR, "a[href*='/marketer/']")

        new_count = 0

        for a in links:
            try:
                href = a.get_attribute("href")
                name = a.text.strip()

                if not name or not href:
                    continue

                url_clean = href.split("?")[0]

                if url_clean in seen:
                    continue

                seen.add(url_clean)

                all_data.append({
                    "name": name,
                    "url": url_clean
                })

                new_count += 1

            except:
                continue

        print(f"Page {page}: {new_count} new marketers")

        # stop if no new data
        if new_count == 0:
            print("No new marketers → stopping")
            break

    driver.quit()

    df = pd.DataFrame(all_data)
    df.to_csv(OUTPUT_FILE, index=False)

    print(f"\nDONE ✔ Total marketers: {len(df)}")


# ---------------------------
# RUN
# ---------------------------
if __name__ == "__main__":
    scrape_marketers(max_pages=450)