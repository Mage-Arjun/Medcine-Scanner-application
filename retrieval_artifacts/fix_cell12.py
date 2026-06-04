import json
import nbformat
import os

with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'r', encoding='utf-8') as f:
    nb = nbformat.read(f, as_version=4)

for cell in nb.cells:
    if cell.cell_type == 'code':
        if 'fail_df = pd.read_csv' in cell.source and 'print(fail_df[' in cell.source:
            # Comment out this broken display code
            lines = cell.source.split('\n')
            cell.source = '\n'.join(['# ' + line for line in lines])

with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'w', encoding='utf-8') as f:
    nbformat.write(nb, f)
