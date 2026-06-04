import pandas as pd
import numpy as np
import json
import pickle
import re
import random
import time
from pathlib import Path

try:
    from rapidfuzz import fuzz
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'rapidfuzz', '-q'])
    from rapidfuzz import fuzz

# Load config
config_path = Path('../retrieval_artifacts/retrieval_config.json')
with open(config_path) as f:
    cfg = json.load(f)

OCR_THRESHOLD = cfg.get('ocr_threshold', 0.6)
weights = (
    cfg.get('exact_weight', 0.4),
    cfg.get('fuzzy_weight', 0.3),
    cfg.get('ingredient_weight', 0.2),
    cfg.get('synonym_weight', 0.1)
)
FUZZY_SUCCESS_THRESHOLD = cfg.get('fuzzy_success_threshold', 80)
print('Config loaded:', cfg)

med_path = Path('../retrieval_artifacts/med_data.csv')
med_df = pd.read_csv(med_path)
print('Shape:', med_df.shape)
print('Missing values:\n', med_df.isnull().sum())
med_df.head()

abbrev_dict = {
    'pcm': 'paracetamol',
    'amox': 'amoxicillin',
    'clav': 'clavulanic acid',
    'azithro': 'azithromycin',
    'ibupro': 'ibuprofen'
}
abbr_path = Path('../retrieval_artifacts/abbreviation_dict.pkl')
with open(abbr_path, 'wb') as f:
    pickle.dump(abbrev_dict, f)

def expand_abbreviation(query):
    tokens = query.split()
    return ' '.join([abbrev_dict.get(tok.lower(), tok) for tok in tokens])

print('expand_abbreviation("pcm") ->', expand_abbreviation('pcm'))
print('expand_abbreviation("amox clav") ->', expand_abbreviation('amox clav'))

synonym_dict = {
    'acetaminophen': 'paracetamol',
    'dolo': 'paracetamol',
    'augmentin': 'amoxicillin clavulanic acid',
    'tylenol': 'paracetamol',
    'zithromax': 'azithromycin'
}
syn_path = Path('../retrieval_artifacts/synonym_dict.pkl')
with open(syn_path, 'wb') as f:
    pickle.dump(synonym_dict, f)

def normalize_synonyms(query):
    q = query.lower()
    for syn, canonical in synonym_dict.items():
        q = re.sub(r'\b' + re.escape(syn) + r'\b', canonical, q)
    return q

print('normalize_synonyms("dolo") ->', normalize_synonyms('dolo'))
print('normalize_synonyms("augmentin") ->', normalize_synonyms('augmentin'))

# Compound terms that must stay together as single tokens
COMPOUND_TERMS = [
    'amoxicillin clavulanic acid',
    'clavulanic acid',
    'sodium chloride',
]

def decompose_query(query):
    original = query
    expanded = normalize_synonyms(expand_abbreviation(query))
    tokens = []
    temp = expanded.lower()
    # Preserve compound terms (longest first to avoid partial matches)
    for term in sorted(COMPOUND_TERMS, key=len, reverse=True):
        if term in temp:
            tokens.append(term)
            temp = temp.replace(term, ' ')
    # Add remaining single tokens
    tokens.extend([t.strip() for t in temp.split() if t.strip()])
    return {
        'original': original,
        'expanded': expanded,
        'tokens': tokens
    }

# Verify compound preservation
ex = decompose_query('amox clav')
print('amox clav ->', ex)
assert any('clavulanic acid' in t for t in ex['tokens']), 'Compound term not preserved!'
print('Decomposition OK')

def process_query(query):
    """Full preprocessing: abbreviation expansion → synonym normalization → decomposition."""
    q = query.lower().strip()
    q = expand_abbreviation(q)
    q = normalize_synonyms(q)
    decomp = decompose_query(q)
    return {
        'query': decomp['expanded'],
        'tokens': decomp['tokens']
    }

# Verify pipeline
for raw in ['pcm', 'amox clav', 'dolo', 'augmentin']:
    result = process_query(raw)
    print(f'{raw!r:15} → {result["query"]!r:35} | tokens: {result["tokens"]}')

OCR_RULES = [
    (r'rn', 'm'),
    (r'(?<![a-z])0(?![0-9])', 'o'),
    (r'(?<![a-z])5(?![0-9])', 's'),
]

def ocr_correct(query):
    corrected = query.lower()
    for pat, repl in OCR_RULES:
        corrected = re.sub(pat, repl, corrected)
    return corrected

print('ocr_correct("paracetarnol") ->', ocr_correct('paracetarnol'))

def exact_retrieval(query, df):
    """Returns matching rows or empty DataFrame."""
    q = query.lower().strip()
    exact = df[df['corpus_standard'] == q].copy()
    if not exact.empty:
        exact['match_type'] = 'Exact Brand'
        exact['match_score'] = 100.0
    return exact

def fuzzy_retrieval(query, df):
    """Returns best match dict with 'result' and 'score' (0-100)."""
    norm = re.sub(r'[^a-z0-9\s]', ' ', query.lower())
    corpus = df['corpus_normalized'].fillna('').astype(str).tolist()
    ratios = [fuzz.ratio(norm, c) for c in corpus]
    partial = [fuzz.partial_ratio(norm, c) for c in corpus]
    scores = [max(r, p) for r, p in zip(ratios, partial)]
    best_idx = int(np.argmax(scores))
    return {
        'result': df.iloc[best_idx]['name'],
        'score': scores[best_idx],
        'row': df.iloc[best_idx]
    }

def ingredient_retrieval(tokens, df):
    """Returns rows matching any token in ingredient_name (fuzzy)."""
    if not tokens:
        return pd.DataFrame()
    ingredient_names = df['ingredient_name'].fillna('').tolist()
    matched_indices = set()
    for token in tokens:
        for idx, ing in enumerate(ingredient_names):
            if fuzz.partial_ratio(token.lower(), ing.lower()) >= 80:
                matched_indices.add(idx)
    res = df.iloc[list(matched_indices)].copy()
    if not res.empty:
        res['match_type'] = 'Ingredient Match'
    return res

# Smoke test
pq = process_query('pcm')
ex = exact_retrieval(pq['query'], med_df)
fz = fuzzy_retrieval(pq['query'], med_df)
print('Exact rows:', len(ex))
print('Fuzzy best:', fz['result'], '| score:', fz['score'])

def hybrid_score(exact_score, fuzzy_score, ingredient_score, synonym_score, w=weights):
    """
    All inputs normalized to [0, 1].
    exact_score      : 1.0 if exact match, else 0.0
    fuzzy_score      : raw rapidfuzz score / 100
    ingredient_score : matched_ingredient_rows / max(len(tokens), 1)
    synonym_score    : 1.0 if any token in synonym_dict, else 0.0
    """
    exact_n = 1.0 if exact_score > 0 else 0.0
    fuzzy_n = min(fuzzy_score / 100.0, 1.0)
    ing_n = float(ingredient_score)
    syn_n = 1.0 if synonym_score > 0 else 0.0
    w_exact, w_fuzzy, w_ing, w_syn = w
    return (w_exact * exact_n
            + w_fuzzy * fuzzy_n
            + w_ing   * ing_n
            + w_syn   * syn_n)

print('Test hybrid (exact match):', hybrid_score(1, 100, 1, 0))
print('Test hybrid (fuzzy only 90):', hybrid_score(0, 90, 0, 0))


def safe_sample(series, n):
    n = min(n, len(series.dropna()))
    return series.dropna().sample(n=n, random_state=42)

def typo(q):
    if len(q) < 2: return q
    i = random.randint(0, len(q) - 2)
    lst = list(q); lst[i], lst[i+1] = lst[i+1], lst[i]
    return ''.join(lst)

def ocr_err(q):
    return re.sub(r'i', 'l', q)

queries = []

# Exact queries
for name in safe_sample(med_df['name'], 5):
    queries.append({'query': name, 'expected': name, 'category': 'exact'})

# Typo queries
for name in safe_sample(med_df['name'], 3):
    queries.append({'query': typo(name), 'expected': name, 'category': 'typo'})

# OCR corruption
for name in safe_sample(med_df['name'], 3):
    queries.append({'query': ocr_err(name), 'expected': name, 'category': 'ocr'})

# Abbreviation queries
for q, exp in [('pcm', 'Paracetamol'), ('amox', 'Amoxicillin'), ('clav', 'Amoxicillin Clavulanic Acid')]:
    queries.append({'query': q, 'expected': exp, 'category': 'abbreviation'})

# Ingredient queries
for ing in safe_sample(med_df['ingredient_name'], 3):
    matching_names = med_df[med_df['ingredient_name'] == ing]['name'].tolist()
    expected = matching_names[0] if matching_names else ''
    queries.append({'query': ing, 'expected': expected, 'category': 'ingredient'})

# Multi-token queries
queries.append({'query': 'amox clav', 'expected': 'Amoxicillin Clavulanic Acid', 'category': 'multi_token'})

# Real failure / known typo cases
for q, exp in [('paracetmol', 'Paracetamol'), ('azitromycin', 'Azithromycin'), ('ibuproffen', 'Ibuprofen'), ('cetirzine', 'Cetirizine')]:
    queries.append({'query': q, 'expected': exp, 'category': 'typo'})

bench_df = pd.DataFrame(queries).drop_duplicates(subset='query')
bench_path = Path('benchmark_day4.csv')
bench_df.to_csv(bench_path, index=False)
print(f'Benchmark saved -> {bench_path} ({len(bench_df)} queries)')
print(bench_df['category'].value_counts())


def evaluate():
    bench = pd.read_csv('benchmark_day4.csv')
    top1 = 0
    total = 0
    latencies = []
    failures = []

    for _, row in bench.iterrows():
        q = row['query']
        start = time.time()

        # Full preprocessing pipeline
        pq = process_query(q)
        processed_query = pq['query']
        tokens = pq['tokens']

        # Retrieval
        exact_res = exact_retrieval(processed_query, med_df)
        fuzzy_res = fuzzy_retrieval(processed_query, med_df)
        ing_res   = ingredient_retrieval(tokens, med_df)

        exact_score = 1.0 if not exact_res.empty else 0.0
        fuzzy_score = fuzzy_res['score']
        ing_score   = len(ing_res) / max(len(tokens), 1)
        syn_score   = 1.0 if any(tok in synonym_dict for tok in tokens) else 0.0

        # OCR retry: only if exact failed AND fuzzy score is below OCR_THRESHOLD*100
        if exact_score == 0.0 and fuzzy_score < (OCR_THRESHOLD * 100):
            corrected = ocr_correct(processed_query)
            ocr_fuzzy = fuzzy_retrieval(corrected, med_df)
            if ocr_fuzzy['score'] > fuzzy_score:
                fuzzy_res = ocr_fuzzy
                fuzzy_score = ocr_fuzzy['score']

        # Success criterion: strong fuzzy retrieval (>=80) OR exact match
        success = (exact_score > 0) or (fuzzy_score >= FUZZY_SUCCESS_THRESHOLD)

        if success:
            top1 += 1
        else:
            failures.append({
                'query': q,
                'processed': processed_query,
                'failure_type': row.get('category', 'unknown'),
                'score': round(fuzzy_score / 100, 4),
                'fuzzy_score': round(fuzzy_score, 2),
                'reason': 'retrieval_failed'
            })

        latencies.append(time.time() - start)
        total += 1

    metrics = {
        'Top1_Accuracy':  round(top1 / total, 4),
        'Recall_at_1':    f'{top1}/{total}',
        'AvgLatency_ms':  round(sum(latencies) / total * 1000, 2),
        'TotalQueries':   total,
        'FailureCount':   len(failures)
    }

    # # # pd.DataFrame([metrics]).to_csv('retrieval_metrics.csv', index=False)
    # # # pd.DataFrame(failures).to_csv('failure_analysis_day4.csv', index=False)

    print('\n=== Evaluation Metrics ===')
    for k, v in metrics.items():
        print(f'  {k}: {v}')
    return metrics, failures

metrics, failures = evaluate()

fail_df = pd.read_csv('failure_analysis_day4.csv')
print(f'Total failures: {len(fail_df)}')
if not fail_df.empty:
    print('\nFailure breakdown by category:')
    print(fail_df['failure_type'].value_counts())
    print('\nSample failures:')
    print(fail_df[['query','expected','predicted','score']].to_string(index=False))
else:
    print('No failures — all queries above confidence threshold!')

tests = ['paracetmol', 'azitromycin', 'amox clav', 'pcm']

for t in tests:
    start = time.time()

    result = process_query(t)
    query  = result['query']
    tokens = result['tokens']

    exact = exact_retrieval(query, med_df)
    fuzzy = fuzzy_retrieval(query, med_df)
    ing   = ingredient_retrieval(tokens, med_df)

    latency = time.time() - start

    print('=' * 50)
    print(f'Input:        {t}')
    print(f'Processed:    {query}')
    print(f'Tokens:       {tokens}')
    print(f'Fuzzy Result: {fuzzy["result"]} (score: {fuzzy["score"]:.1f})')
    print(f'Exact rows:   {len(exact)} | Ingredient rows: {len(ing)}')
    print(f'Latency:      {latency:.4f}s')

print('\n' + '='*60)
print('MedScan Day 4 — Retrieval Enhancement: COMPLETE')
print('='*60)
print('\nGenerated files:')
for f in ['benchmark_day4.csv', 'retrieval_metrics.csv',
          'failure_analysis_day4.csv',
          '../retrieval_artifacts/abbreviation_dict.pkl', '../retrieval_artifacts/synonym_dict.pkl',
          '../retrieval_artifacts/retrieval_config.json']:
    p = Path(f)
    status = '✓' if p.exists() else '✗ MISSING'
    print(f'  {status}  {f}')

print('\nFinal metrics:')
m = pd.read_csv('retrieval_metrics.csv').iloc[0]
print(f'  Top-1 Accuracy : {float(m["Top1_Accuracy"]):.1%}')
print(f'  Recall@1       : {m["Recall_at_1"]}')
print(f'  Avg Latency    : {m["AvgLatency_ms"]:.2f} ms')
print(f'  Total Queries  : {int(m["TotalQueries"])}')
print(f'  Failures       : {int(m["FailureCount"])}')


def evaluate():
    benchmark = pd.read_csv("benchmark_day4.csv")
    total = len(benchmark)
    top1_correct = 0
    top3_correct = 0
    failures = []
    latencies = []

    for _, row in benchmark.iterrows():
        query = row['query']
        expected = str(row['expected'])
        category = row['category']
        start = time.time()

        processed = process_query(query)
        query_processed = processed['query']
        tokens = processed['tokens']

        exact = exact_retrieval(query_processed, med_df)
        fuzzy = fuzzy_retrieval(query_processed, med_df)
        ingredient = ingredient_retrieval(tokens, med_df)

        predictions = []
        if len(exact) > 0:
            predictions.extend(exact['name'].tolist())
        if len(ingredient) > 0:
            predictions.extend(ingredient['name'].tolist())
        if fuzzy:
            predictions.append(fuzzy['result'])

        # remove duplicates
        predictions = list(dict.fromkeys(predictions))

        top1 = predictions[:1]
        top3 = predictions[:3]

        if any(expected.lower() in str(x).lower() for x in top1):
            top1_correct += 1
            is_fail = False
        else:
            is_fail = True

        if any(expected.lower() in str(x).lower() for x in top3):
            top3_correct += 1

        latency = time.time() - start
        latencies.append(latency)

        if is_fail:
            score = fuzzy.get('score', 0) if fuzzy else 0
            
            # Check for dataset coverage failure
            if not med_df['name'].str.contains(expected, case=False, na=False).any():
                failure_type = "DATASET_COVERAGE_FAILURE"
                root_cause = "Expected medicine does not exist in the dataset"
            else:
                failure_type = classify_failure(query, query_processed, score)
                root_cause = f"Retrieval returned {top1[0] if top1 else 'None'} instead of {expected}"

            failures.append({
                "query": query,
                "expected": expected,
                "predicted": top1[0] if top1 else "None",
                "score": score,
                "failure_type": failure_type,
                "root_cause": root_cause
            })

    metrics = {
        "Top1_Accuracy": round(top1_correct / total, 4),
        "Top3_Accuracy": round(top3_correct / total, 4),
        "Recall": round(top1_correct / total, 4),
        "Average_Latency_ms": round(sum(latencies) / len(latencies) * 1000, 2),
        "Failure_Count": len(failures)
    }

    pd.DataFrame([metrics]).to_csv("retrieval_metrics.csv", index=False)
    pd.DataFrame(failures).to_csv("failure_analysis_day4.csv", index=False)

    print("=" * 60)
    print("MedScan Day 4 Results")
    print("=" * 60)
    for k, v in metrics.items():
        print(f"{k}: {v}")
    
    print("\nFailure summary:")
    if len(failures) > 0:
        display(pd.DataFrame(failures))
    else:
        print("No failures detected")
        
    return metrics, failures

metrics, failures = evaluate()


