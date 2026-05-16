import pandas as pd
import random

# ---------------------------
# LOAD DATA
# ---------------------------
FILE = "medicine_urls_full.csv"   # change if needed

df = pd.read_csv(FILE)

print("\n==============================")
print("DATASET VALIDATION REPORT")
print("==============================\n")


# ---------------------------
# BASIC INFO
# ---------------------------
print("🔹 BASIC INFO")
print("Total rows:", len(df))
print("Columns:", list(df.columns))


# ---------------------------
# UNIQUE COUNTS
# ---------------------------
print("\n🔹 UNIQUENESS")

if "medicine_url" in df.columns:
    unique_urls = df["medicine_url"].nunique()
    print("Unique medicine URLs:", unique_urls)
    print("Duplicate URLs:", len(df) - unique_urls)

if "marketer" in df.columns:
    unique_marketers = df["marketer"].nunique()
    print("Unique marketers:", unique_marketers)


# ---------------------------
# MISSING VALUES
# ---------------------------
print("\n🔹 MISSING VALUES")
print(df.isnull().sum())


# ---------------------------
# DUPLICATE CHECK
# ---------------------------
print("\n🔹 DUPLICATE ROWS")

duplicates = df.duplicated(subset=["medicine_url"], keep=False)
dup_count = duplicates.sum()

print("Duplicate rows:", dup_count)

if dup_count > 0:
    print("\nSample duplicates:")
    print(df[duplicates].head(10))


# ---------------------------
# PER MARKETER DISTRIBUTION
# ---------------------------
print("\n🔹 MEDICINES PER MARKETER")

if "marketer" in df.columns:
    dist = df.groupby("marketer").size()

    print("Min:", dist.min())
    print("Max:", dist.max())
    print("Mean:", round(dist.mean(), 2))
    print("Median:", dist.median())

    print("\nTop 10 marketers by count:")
    print(dist.sort_values(ascending=False).head(10))


# ---------------------------
# RANDOM SAMPLE CHECK
# ---------------------------
print("\n🔹 RANDOM SAMPLE (MANUAL CHECK)")

sample = df.sample(min(10, len(df)))

for i, row in sample.iterrows():
    print(f"- {row.get('medicine_name', 'N/A')} → {row.get('medicine_url', 'N/A')}")


# ---------------------------
# URL QUALITY CHECK
# ---------------------------
print("\n🔹 URL FORMAT CHECK")

if "medicine_url" in df.columns:
    invalid_urls = df[~df["medicine_url"].str.contains("/drugs/|/otc/", na=False)]
    print("Invalid URL format:", len(invalid_urls))


# ---------------------------
# FINAL SUMMARY
# ---------------------------
print("\n==============================")
print("SUMMARY")
print("==============================")

print("✔ Dataset size:", len(df))
print("✔ Unique medicines:", df["medicine_url"].nunique() if "medicine_url" in df.columns else "N/A")
print("✔ Duplicate %:", round((1 - df["medicine_url"].nunique()/len(df)) * 100, 2) if "medicine_url" in df.columns else "N/A")

print("\nDONE ✔")