import json
with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'r', encoding='utf-8') as f:
    nb = json.load(f)
with open('notebook_code.py', 'w', encoding='utf-8') as f:
    for cell in nb['cells']:
        if cell['cell_type'] == 'code':
            source = ''.join(cell['source']) if isinstance(cell['source'], list) else cell['source']
            f.write(source + '\n\n')
