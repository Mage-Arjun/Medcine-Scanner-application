import json
import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
import os

with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'r', encoding='utf-8') as f:
    nb = nbformat.read(f, as_version=4)

new_evaluate_cell = """
def classify_failure(query, query_processed, score):
    if len(query) < 4:
        return 'Abbreviation Failure'
    elif score < 60:
        return 'OCR Failure'
    return 'Ranking Failure'

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

        exact_score = 1.0 if not exact.empty else 0.0
        fuzzy_score = fuzzy.get('score', 0)
        ing_score   = len(ingredient) / max(len(tokens), 1)
        syn_score   = 1.0 if any(tok in synonym_dict for tok in tokens) else 0.0

        if exact_score == 0.0 and fuzzy_score < (OCR_THRESHOLD * 100):
            corrected = ocr_correct(query_processed)
            ocr_fuzzy = fuzzy_retrieval(corrected, med_df)
            if ocr_fuzzy and ocr_fuzzy.get('score', 0) > fuzzy_score:
                fuzzy = ocr_fuzzy
                fuzzy_score = ocr_fuzzy['score']

        candidates = {}
        if not exact.empty:
            for n in exact['name'].tolist():
                candidates[n] = max(candidates.get(n, 0), hybrid_score(1, 0, 0, 0))
                
        if fuzzy:
            n = fuzzy['result']
            candidates[n] = max(candidates.get(n, 0), hybrid_score(0, fuzzy_score, 0, syn_score))
            
        if not ingredient.empty:
            for n in ingredient['name'].tolist()[:10]: 
                candidates[n] = max(candidates.get(n, 0), hybrid_score(0, 0, ing_score, syn_score))
                
        sorted_preds = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        predictions = [x[0] for x in sorted_preds]

        top1 = predictions[:1]
        top3 = predictions[:3]

        if any(expected.lower() == str(x).lower() for x in top1):
            top1_correct += 1
            is_fail = False
        else:
            is_fail = True

        if any(expected.lower() == str(x).lower() for x in top3):
            top3_correct += 1

        latency = time.time() - start
        latencies.append(latency)

        if is_fail:
            if not med_df['name'].str.lower().eq(expected.lower()).any():
                failure_type = "DATASET_COVERAGE_FAILURE"
                root_cause = "Expected medicine does not exist in the dataset"
            else:
                failure_type = classify_failure(query, query_processed, fuzzy_score)
                root_cause = f"Retrieval returned {top1[0] if top1 else 'None'} instead of {expected}"

            failures.append({
                "query": query,
                "expected": expected,
                "predicted": top1[0] if top1 else "None",
                "score": fuzzy_score,
                "failure_type": failure_type,
                "root_cause": root_cause
            })

    metrics = {
        "Top1_Accuracy": round(top1_correct / total, 4),
        "Top3_Accuracy": round(top3_correct / total, 4),
        "Recall": round(top1_correct / total, 4),
        "Average_Latency_ms": round(sum(latencies) / max(len(latencies), 1) * 1000, 2),
        "Failure_Count": len(failures)
    }

    pd.DataFrame([metrics]).to_csv("retrieval_metrics.csv", index=False)
    pd.DataFrame(failures).to_csv("failure_analysis_day4.csv", index=False)

    print("=" * 60)
    print("MedScan Day 4 Results")
    print("=" * 60)
    for k, v in metrics.items():
        print(f"{k}: {v}")
    
    print("\\nFailure summary:")
    if len(failures) > 0:
        display(pd.DataFrame(failures))
    else:
        print("No failures detected")
        
    return metrics, failures

metrics, failures = evaluate()
"""

# Find the cell containing 'def evaluate():' that has the buggy classify_failure logic (the last one)
for cell in reversed(nb.cells):
    if cell.cell_type == 'code' and 'def evaluate():' in cell.source and 'classify_failure' in cell.source:
        cell.source = new_evaluate_cell
        break

with open('MedScan_Day4_Retrieval_Enhancement.ipynb', 'w', encoding='utf-8') as f:
    nbformat.write(nb, f)

print("Notebook updated successfully.")
