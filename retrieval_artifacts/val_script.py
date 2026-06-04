import pandas as pd
import time
import json
import re
try:
    from rapidfuzz import fuzz
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'rapidfuzz', '-q'])
    from rapidfuzz import fuzz

abbrev_dict = {
    'pcm': 'paracetamol',
    'amox': 'amoxicillin',
    'clav': 'clavulanic acid',
    'azithro': 'azithromycin',
    'ibupro': 'ibuprofen'
}
def expand_abbreviation(query):
    tokens = query.split()
    return ' '.join([abbrev_dict.get(tok.lower(), tok) for tok in tokens])

synonym_dict = {
    'acetaminophen': 'paracetamol',
    'dolo': 'paracetamol',
    'augmentin': 'amoxicillin clavulanic acid',
    'tylenol': 'paracetamol',
    'zithromax': 'azithromycin'
}
def normalize_synonyms(query):
    q = query.lower()
    for syn, canonical in synonym_dict.items():
        q = re.sub(r'\b' + re.escape(syn) + r'\b', canonical, q)
    return q

COMPOUND_TERMS = ['amoxicillin clavulanic acid', 'clavulanic acid', 'sodium chloride']
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

def process_query(query):
    q = query.lower().strip()
    q = expand_abbreviation(q)
    q = normalize_synonyms(q)
    decomp = decompose_query(q)
    return {'query': decomp['expanded'], 'tokens': decomp['tokens']}

def exact_retrieval(query, df):
    q = query.lower().strip()
    exact = df[df['corpus_standard'] == q].copy()
    return exact

def fuzzy_retrieval(query, df):
    norm = re.sub(r'[^a-z0-9\s]', ' ', query.lower())
    corpus = df['corpus_normalized'].fillna('').astype(str).tolist()
    ratios = [fuzz.ratio(norm, c) for c in corpus]
    partial = [fuzz.partial_ratio(norm, c) for c in corpus]
    scores = [max(r, p) for r, p in zip(ratios, partial)]
    best_idx = int(pd.Series(scores).idxmax())
    return {
        'result': df.iloc[best_idx]['name'],
        'score': scores[best_idx]
    }

def ingredient_retrieval(tokens, df):
    if not tokens: return pd.DataFrame()
    ingredient_names = df['ingredient_name'].fillna('').tolist()
    matched_indices = set()
    for token in tokens:
        for idx, ing in enumerate(ingredient_names):
            if fuzz.partial_ratio(token.lower(), ing.lower()) >= 80:
                matched_indices.add(idx)
    res = df.iloc[list(matched_indices)].copy()
    return res

OCR_RULES = [(r'rn', 'm'), (r'(?<![a-z])0(?![0-9])', 'o'), (r'(?<![a-z])5(?![0-9])', 's')]
def ocr_correct(query):
    corrected = query.lower()
    for pat, repl in OCR_RULES:
        corrected = re.sub(pat, repl, corrected)
    return corrected

weights = (0.4, 0.3, 0.2, 0.1)
def hybrid_score(exact_score, fuzzy_score, ingredient_score, synonym_score, w=weights):
    exact_n = 1.0 if exact_score > 0 else 0.0
    fuzzy_n = min(fuzzy_score / 100.0, 1.0)
    ing_n = float(ingredient_score)
    syn_n = 1.0 if synonym_score > 0 else 0.0
    return w[0]*exact_n + w[1]*fuzzy_n + w[2]*ing_n + w[3]*syn_n

med_df = pd.read_csv('../retrieval_artifacts/med_data.csv')
queries = [
    ("paracetmol", "Paracetamol"),
    ("azitromycin", "Azithromycin"),
    ("amox clav", "Amoxicillin Clavulanic Acid"),
    ("pcm", "Paracetamol")
]

with open("critical_validation.txt", "w") as f:
    for q, expected in queries:
        pq = process_query(q)
        qp = pq['query']
        toks = pq['tokens']
        
        exact = exact_retrieval(qp, med_df)
        fuzzy = fuzzy_retrieval(qp, med_df)
        ing = ingredient_retrieval(toks, med_df)
        
        exact_s = 1.0 if not exact.empty else 0.0
        fuzzy_s = fuzzy['score']
        ing_s = len(ing) / max(len(toks), 1)
        syn_s = 1.0 if any(t in synonym_dict for t in toks) else 0.0
        
        if exact_s == 0 and fuzzy_s < 60:
            corrected = ocr_correct(qp)
            ocr_fz = fuzzy_retrieval(corrected, med_df)
            if ocr_fz['score'] > fuzzy_s:
                fuzzy = ocr_fz
                fuzzy_s = ocr_fz['score']
                
        candidates = {}
        if not exact.empty:
            for n in exact['name'].tolist():
                candidates[n] = max(candidates.get(n, 0), hybrid_score(1, 0, 0, 0))
        if fuzzy:
            candidates[fuzzy['result']] = max(candidates.get(fuzzy['result'], 0), hybrid_score(0, fuzzy_s, 0, syn_s))
        if not ing.empty:
            for n in ing['name'].tolist()[:10]:
                candidates[n] = max(candidates.get(n, 0), hybrid_score(0, 0, ing_s, syn_s))
                
        sorted_preds = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        top1 = sorted_preds[0] if sorted_preds else ("None", 0)
        
        f.write(f"Input: {q}\n")
        f.write(f"Processed Query: {qp}\n")
        f.write(f"Expected Result: {expected}\n")
        f.write(f"Predicted Result: {top1[0]}\n")
        f.write(f"Score: {top1[1]:.4f}\n")
        success = "Success" if top1[0].lower() == expected.lower() else "Failure"
        f.write(f"Success / Failure: {success}\n\n")

