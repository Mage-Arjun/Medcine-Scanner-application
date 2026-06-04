import pandas as pd
import json
from pathlib import Path
import re
from rapidfuzz import fuzz

med_df = pd.read_csv('../retrieval_artifacts/med_data.csv')
with open('../retrieval_artifacts/retrieval_config.json') as f:
    cfg = json.load(f)

# from notebook
abbrev_dict = {'pcm': 'paracetamol', 'amox': 'amoxicillin', 'clav': 'clavulanic acid', 'azithro': 'azithromycin', 'ibupro': 'ibuprofen'}
synonym_dict = {'acetaminophen': 'paracetamol', 'dolo': 'paracetamol', 'augmentin': 'amoxicillin clavulanic acid', 'tylenol': 'paracetamol', 'zithromax': 'azithromycin'}
COMPOUND_TERMS = ['amoxicillin clavulanic acid', 'clavulanic acid', 'sodium chloride']
OCR_RULES = [(r'rn', 'm'), (r'(?<![a-z])0(?![0-9])', 'o'), (r'(?<![a-z])5(?![0-9])', 's')]
OCR_THRESHOLD = cfg.get('ocr_threshold', 0.6)

def expand_abbreviation(query):
    tokens = query.split()
    return ' '.join([abbrev_dict.get(tok.lower(), tok) for tok in tokens])

def normalize_synonyms(query):
    q = query.lower()
    for syn, canonical in synonym_dict.items():
        q = re.sub(r'\b' + re.escape(syn) + r'\b', canonical, q)
    return q

def decompose_query(query):
    original = query
    expanded = normalize_synonyms(expand_abbreviation(query))
    tokens = []
    temp = expanded.lower()
    for term in sorted(COMPOUND_TERMS, key=len, reverse=True):
        if term in temp:
            tokens.append(term)
            temp = temp.replace(term, ' ')
    tokens.extend([t.strip() for t in temp.split() if t.strip()])
    return {'original': original, 'expanded': expanded, 'tokens': tokens}

def ocr_correct(query):
    corrected = query.lower()
    for pat, repl in OCR_RULES:
        corrected = re.sub(pat, repl, corrected)
    return corrected

def exact_retrieval(query, df):
    q = query.lower().strip()
    return df[df['corpus_standard'] == q].copy()

def fuzzy_retrieval(query, df):
    norm = re.sub(r'[^a-z0-9\s]', ' ', query.lower())
    corpus = df['corpus_normalized'].fillna('').astype(str).tolist()
    ratios = [fuzz.ratio(norm, c) for c in corpus]
    partial = [fuzz.partial_ratio(norm, c) for c in corpus]
    scores = [max(r, p) for r, p in zip(ratios, partial)]
    best_idx = int(np.argmax(scores))
    return {'result': df.iloc[best_idx]['name'], 'score': scores[best_idx], 'row': df.iloc[best_idx]}

def ingredient_retrieval(tokens, df):
    if not tokens: return pd.DataFrame()
    ingredient_names = df['ingredient_name'].fillna('').tolist()
    matched_indices = set()
    for token in tokens:
        for idx, ing in enumerate(ingredient_names):
            if fuzz.partial_ratio(token.lower(), ing.lower()) >= 80:
                matched_indices.add(idx)
    return df.iloc[list(matched_indices)].copy()

import numpy as np

def trace_query(q):
    print("---------------------------------")
    print(f"Input Query: {q}")
    print("↓")
    
    q_abbrev = expand_abbreviation(q.lower().strip())
    print(f"Abbreviation Expansion: {q_abbrev}")
    print("↓")
    
    q_syn = normalize_synonyms(q_abbrev)
    print(f"Synonym Normalization: {q_syn}")
    print("↓")
    
    q_ocr = q_syn
    # simulate evaluation logic condition for OCR retry
    exact_res = exact_retrieval(q_syn, med_df)
    fuzzy_res = fuzzy_retrieval(q_syn, med_df)
    if exact_res.empty and fuzzy_res['score'] < OCR_THRESHOLD * 100:
        q_ocr = ocr_correct(q_syn)
        print(f"OCR Correction (if applied): {q_ocr}")
    else:
        print(f"OCR Correction (if applied): [Not applied, score={fuzzy_res['score']}]")
    print("↓")
    
    decomp = decompose_query(q)
    tokens = decomp['tokens']
    print(f"Tokenization: {tokens}")
    print("↓")
    
    exact_res = exact_retrieval(q_ocr, med_df)
    if not exact_res.empty:
        print(f"Exact Retrieval: {exact_res['name'].tolist()}")
    else:
        print("Exact Retrieval: None")
    print("↓")
    
    fuzzy_res = fuzzy_retrieval(q_ocr, med_df)
    print(f"Fuzzy Retrieval: {fuzzy_res['result']} (Score: {fuzzy_res['score']})")
    print("↓")
    
    ing_res = ingredient_retrieval(tokens, med_df)
    if not ing_res.empty:
        print(f"Ingredient Retrieval: {ing_res['name'].tolist()}")
    else:
        print("Ingredient Retrieval: None")
    print("↓")
    
    predictions = []
    if not exact_res.empty: predictions.extend(exact_res['name'].tolist())
    if not ing_res.empty: predictions.extend(ing_res['name'].tolist())
    predictions.append(fuzzy_res['result'])
    predictions = list(dict.fromkeys(predictions))
    
    print(f"Final Ranked Result: {predictions}")

for t in ['pcm', 'amox clav', 'paracetmol', 'azitromycin']:
    trace_query(t)
