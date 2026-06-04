import pandas as pd
import re

print("Loading data...")
df = pd.read_csv('../data/final/medicine_ready_v2.csv', low_memory=False)
print("Data loaded. Shape:", df.shape)

out = pd.DataFrame()
out['name'] = df['name']
out['generic_name'] = df['generic_name']
out['ingredient_name'] = df['composition']
out['corpus_standard'] = df['name'].astype(str).str.lower().str.strip()
out['corpus_normalized'] = df['name'].astype(str).str.lower().apply(lambda x: re.sub(r'[^a-z0-9\s]', ' ', x))

out.to_csv('../retrieval_artifacts/med_data.csv', index=False)
print("Done. Saved to med_data.csv. Shape:", out.shape)
