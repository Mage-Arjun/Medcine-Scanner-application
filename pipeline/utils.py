import requests
import time
import random

HEADERS = {
    "User-Agent": "Mozilla/5.0"
}

def get_soup(url):
    """Fetch page and return BeautifulSoup object"""
    from bs4 import BeautifulSoup

    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
        return BeautifulSoup(r.text, "html.parser")
    except Exception as e:
        print(f"Failed: {url} -> {e}")
        return None


def polite_sleep(min_s=1, max_s=3):
    """Avoid getting blocked"""
    time.sleep(random.uniform(min_s, max_s))