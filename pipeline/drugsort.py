import pandas as pd

df = pd.read_csv("medicine_urls_full.csv")

# keep only drugs
df_drugs = df[df["medicine_url"].str.contains("/drugs/", na=False)]

df_drugs.to_csv("medicines_drugs_only.csv", index=False)

print("Original:", len(df))
print("Drugs only:", len(df_drugs))