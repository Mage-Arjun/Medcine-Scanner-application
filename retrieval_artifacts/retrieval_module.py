import json
import pickle
import re
from typing import List, Tuple, Dict
import pandas as pd
from rapidfuzz import fuzz

# Load dictionaries (could be generated elsewhere)
def load_dict(path: str) -> Dict[str, str]:
    try:
        with open(path, 'rb') as f:
            return pickle.load(f)
    except FileNotFoundError:
        return {}

# Abbreviation expansion
def expand_abbreviation(query: str, abbrev_dict: Dict[str, str]) -> str:
    tokens = query.split()
    expanded = [abbrev_dict.get(tok, tok) for tok in tokens]
    return ' '.join(expanded)

# Synonym normalization (maps synonyms to canonical term)
def normalize_synonyms(query: str, synonym_dict: Dict[str, str]) -> str:
    tokens = query.split()
    normalized = [synonym_dict.get(tok, tok) for tok in tokens]
    return ' '.join(normalized)

# Multi-token decomposition (returns list of individual tokens and expanded tokens)
def decompose_query(query: str) -> List[str]:
    # Simple split on whitespace and punctuation
    cleaned = re.sub(r"[^a-z0-9]+", " ", query.lower())
    tokens = cleaned.split()
    return tokens

# OCR correction engine (simple rule‑based)
OCR_RULES = [
    (r"i", "l"),
    (r"rn", "m"),
    (r"0", "o"),
    (r"1", "l"),
    (r"5", "s"),
]

def ocr_correct(query: str) -> str:
    corrected = query.lower()
    for pattern, repl in OCR_RULES:
        corrected = re.sub(pattern, repl, corrected)
    return corrected

# Hybrid scoring – normalizes sub‑scores to [0,1] and applies weighted sum
def hybrid_score(exact_score: float, fuzzy_score: float, ingredient_score: float, synonym_score: float,
                 weights: Tuple[float, float, float, float] = (0.4, 0.3, 0.2, 0.1)) -> float:
    # Normalization as per specification
    exact_norm = 1.0 if exact_score > 0 else 0.0
    fuzzy_norm = fuzzy_score / 100.0
    ingredient_norm = ingredient_score  # already a ratio (matched/total)
    synonym_norm = 1.0 if synonym_score > 0 else 0.0
    w_exact, w_fuzzy, w_ing, w_syn = weights
    return (w_exact * exact_norm + w_fuzzy * fuzzy_norm + w_ing * ingredient_norm + w_syn * synonym_norm)

# Wrapper that runs the full retrieval pipeline for a query
def retrieve(query: str, med_df: pd.DataFrame, ing_df: pd.DataFrame,
             abbrev_dict_path: str = "data/abbreviation_dict.pkl",
             synonym_dict_path: str = "data/synonym_dict.pkl",
             config_path: str = "data/retrieval_config.json") -> pd.DataFrame:
    # Load config
    with open(config_path, "r") as f:
        cfg = json.load(f)
    # Load dictionaries
    abbrev_dict = load_dict(abbrev_dict_path)
    synonym_dict = load_dict(synonym_dict_path)

    # 1. Initial Fuzzy search
    fuzzy_res = search_fuzzy(query, med_df)
    fuzzy_score = fuzzy_res['match_score'].max() if not fuzzy_res.empty else 0.0

    # 2. Exact search
    exact_res = search_exact(query, med_df)
    if not exact_res.empty:
        exact_score = 1.0
    else:
        exact_score = 0.0
        # 3. Conditional OCR correction
        if fuzzy_score < cfg.get("ocr_threshold", 0.6) * 100:
            corrected = ocr_correct(query)
            if corrected != query:
                exact_res = search_exact(corrected, med_df)
                if not exact_res.empty:
                    exact_score = 1.0
                    query = corrected
    # 4. Expand abbreviation & synonyms
    expanded = expand_abbreviation(query, abbrev_dict)
    expanded = normalize_synonyms(expanded, synonym_dict)
    # 5. Decompose for ingredient search
    tokens = decompose_query(expanded)
    ing_res = search_by_ingredient(tokens, ing_df)
    ingredient_score = len(ing_res) / max(len(tokens), 1)
    # 6. Synonym match flag (simple check if any token matched synonym dict)
    synonym_score = 1.0 if any(tok in synonym_dict for tok in tokens) else 0.0

    # 7. Hybrid score
    final = hybrid_score(exact_score, fuzzy_score, ingredient_score, synonym_score,
                         weights=(cfg.get("exact_weight", 0.4), cfg.get("fuzzy_weight", 0.3),
                                  cfg.get("ingredient_weight", 0.2), cfg.get("synonym_weight", 0.1)))
    # Assemble result DataFrame
    results = pd.concat([exact_res, fuzzy_res, ing_res], ignore_index=True).drop_duplicates()
    if not results.empty:
        results['final_score'] = final
    return results.sort_values('final_score', ascending=False)

def search_exact(query: str, df: pd.DataFrame) -> pd.DataFrame:
    """Exact and prefix brand/generic matching.
    Returns a DataFrame with match_type and match_score columns.
    """
    q = query.lower().strip()
    # Exact brand name match on standard corpus
    exact = df[df['corpus_standard'] == q].copy()
    if not exact.empty:
        exact['match_type'] = 'Exact Brand'
        exact['match_score'] = 100.0
        return exact
    # Exact generic name match
    exact_generic = df[df['generic_name'].str.lower() == q].copy()
    if not exact_generic.empty:
        exact_generic['match_type'] = 'Exact Generic'
        exact_generic['match_score'] = 95.0
        return exact_generic
    # Prefix brand match
    prefix = df[df['corpus_standard'].str.startswith(q, na=False)].copy()
    if not prefix.empty:
        prefix['match_type'] = 'Prefix Brand'
        prefix['match_score'] = 90.0
        prefix['len'] = prefix['corpus_standard'].str.len()
        prefix = prefix.sort_values('len').drop(columns=['len'])
        return prefix
    return pd.DataFrame()

def search_fuzzy(query: str, df: pd.DataFrame, top_k: int = 5, threshold: float = 65.0) -> pd.DataFrame:
    """Typo‑tolerant fuzzy search using RapidFuzz.
    Returns top_k results with fuzzy match_score.
    """
    # Normalize query similarly to notebook
    def normalize(text: str) -> str:
        text = text.lower()
        text = re.sub(r'[^a-z0-9\s]', ' ', text)
        return re.sub(r'\s+', ' ', text).strip()
    norm_query = normalize(query)
    corpus = df['corpus_normalized'].tolist()
    ratio_scores = [fuzz.ratio(norm_query, doc) for doc in corpus]
    partial_scores = [fuzz.partial_ratio(norm_query, doc) for doc in corpus]
    df_res = df.copy()
    df_res['fuzz_ratio'] = ratio_scores
    df_res['fuzz_partial'] = partial_scores
    df_res['match_score'] = df_res['fuzz_ratio'] * 0.7 + df_res['fuzz_partial'] * 0.3
    df_res = df_res[df_res['match_score'] >= threshold]
    df_res = df_res.sort_values('match_score', ascending=False).head(top_k)
    df_res['match_type'] = 'Fuzzy Match'
    return df_res[['name', 'generic_name', 'match_type', 'match_score', 'fuzz_ratio']]

def search_by_ingredient(tokens: List[str], df: pd.DataFrame) -> pd.DataFrame:
    """Ingredient‑based retrieval.
    Returns rows where any token appears in the ingredient_name column.
    Each result gets a match_score based on the proportion of query tokens found in the ingredient string.
    """
    if not tokens:
        return pd.DataFrame()
    pattern = '|'.join(map(re.escape, tokens))
    mask = df['ingredient_name'].str.contains(pattern, case=False, regex=True, na=False)
    res = df[mask].copy()
    if not res.empty:
        res['match_type'] = 'Ingredient Match'
        # Compute per‑row score: proportion of tokens present
        def row_score(text: str) -> float:
            lower = text.lower()
            matches = sum(tok in lower for tok in tokens)
            return (matches / len(tokens)) * 100.0
        res['match_score'] = res['ingredient_name'].apply(row_score)
    return res
