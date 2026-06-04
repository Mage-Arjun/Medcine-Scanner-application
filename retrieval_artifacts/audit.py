import pandas as pd
from pathlib import Path
import json

med_path = Path('../retrieval_artifacts/med_data.csv')
med_df = pd.read_csv(med_path)

print("--- PHASE 1 ---")
print("SHAPE:", med_df.shape)
print("COLUMNS:", med_df.columns)
print("HEAD20:\n", med_df[['name']].head(20))

targets = ['Azithromycin', 'Cetirizine', 'Amoxicillin Clavulanic Acid']
print("PRESENCE:")
for t in targets:
    present = med_df['name'].str.contains(t, case=False, na=False).any()
    print(f"{t}: {present}")

print("\n--- PHASE 2 & 4 ---")
# load notebook functions for tracing
import nbformat
with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'r', encoding='utf-8') as f:
    nb = nbformat.read(f, as_version=4)

for cell in nb.cells:
    if cell.cell_type == 'code':
        source = cell.source
        # Avoid running evaluate() right away
        if 'def evaluate():' in source: continue
        if 'evaluate()' in source: continue
        # execute cell
        # actually let's just write a clean testing script from the notebook logic
