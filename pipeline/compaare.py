import pandas as pd
import os
 
INPUT_FILE = "medicines_drugs_only.csv"
OUTPUT_FILE = "medicine_details_full.csv"
 
input_urls = set(pd.read_csv(INPUT_FILE)["medicine_url"].dropna().tolist())
 
if not os.path.exists(OUTPUT_FILE):
    print("Output file not found.")
else:
    output_urls = set(pd.read_csv(OUTPUT_FILE)["url"].dropna().tolist())
 
    done        = input_urls & output_urls
    missing     = input_urls - output_urls
    extra       = output_urls - input_urls
 
    print(f"Total in input CSV     : {len(input_urls)}")
    print(f"Total in output CSV    : {len(output_urls)}")
    print(f"Matched (done)         : {len(done)}")
    print(f"Missing (not scraped)  : {len(missing)}")
    print(f"Extra (not in input)   : {len(extra)}")
 
    if missing:
        pd.DataFrame(sorted(missing), columns=["url"]).to_csv("missing_urls.csv", index=False)
        print(f"\n✅ Saved missing URLs to missing_urls.csv")
 
    if extra:
        pd.DataFrame(sorted(extra), columns=["url"]).to_csv("extra_urls.csv", index=False)
        print(f"⚠ Saved extra URLs to extra_urls.csv")