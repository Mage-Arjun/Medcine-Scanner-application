"""MedScan retrieval engine."""

from __future__ import annotations

import json
import pickle
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

import pandas as pd
from rapidfuzz import fuzz

from backend.artifact_loader import (
    load_abbreviation_dict,
    load_config,
    load_ingredient_dataset,
    load_medicine_dataset,
    load_synonym_dict,
)
from backend.query_processor import (
    decompose_query,
    expand_abbreviation,
    normalize_synonyms,
    ocr_correct,
)


EXACT_WEIGHT = 0.5
FUZZY_WEIGHT = 0.3
INGREDIENT_WEIGHT = 0.1
SYNONYM_WEIGHT = 0.1
DEFAULT_WEIGHTS = (EXACT_WEIGHT, FUZZY_WEIGHT, INGREDIENT_WEIGHT, SYNONYM_WEIGHT)
MATCH_PRIORITY = {
    "Exact Brand": 5,
    "Exact Generic": 4,
    "Prefix Brand": 3,
    "Fuzzy Match": 2,
    "Ingredient Match": 1,
}


def load_dict(path: str) -> Dict[str, str]:
    try:
        with open(path, "rb") as handle:
            return pickle.load(handle)
    except FileNotFoundError:
        return {}


def _load_config_from_path(path: str) -> Dict[str, object]:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def _weights_from_config(cfg: Dict[str, object]) -> Tuple[float, float, float, float]:
    return DEFAULT_WEIGHTS


def _normalize_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _name_fuzzy_norm(query: str, name: str) -> float:
    norm_query = _normalize_text(query)
    norm_name = _normalize_text(name)
    if not norm_query or not norm_name:
        return 0.0
    ratio_score = fuzz.ratio(norm_query, norm_name)
    partial_score = fuzz.partial_ratio(norm_query, norm_name)
    return min(max((ratio_score * 0.7 + partial_score * 0.3) / 100.0, 0.0), 1.0)


def search_exact(query: str, df: pd.DataFrame) -> pd.DataFrame:
    q = query.lower().strip()
    exact = df[df["corpus_standard"] == q].copy()
    if not exact.empty:
        exact["match_type"] = "Exact Brand"
        exact["match_score"] = 100.0
        return exact

    exact_generic = df[df["generic_name"].astype(str).str.lower() == q].copy()
    if not exact_generic.empty:
        exact_generic["match_type"] = "Exact Generic"
        exact_generic["match_score"] = 95.0
        return exact_generic

    prefix = df[df["corpus_standard"].str.startswith(q, na=False)].copy()
    if not prefix.empty:
        prefix["match_type"] = "Prefix Brand"
        prefix["match_score"] = 90.0
        prefix["len"] = prefix["corpus_standard"].str.len()
        prefix = prefix.sort_values("len").drop(columns=["len"])
        return prefix
    return pd.DataFrame()


def search_fuzzy(query: str, df: pd.DataFrame, top_k: int = 5, threshold: float = 65.0) -> pd.DataFrame:
    norm_query = _normalize_text(query)
    corpus = df["corpus_normalized"].fillna("").astype(str).tolist()
    ratio_scores = [fuzz.ratio(norm_query, doc) for doc in corpus]
    partial_scores = [fuzz.partial_ratio(norm_query, doc) for doc in corpus]
    df_res = df.copy()
    df_res["fuzz_ratio"] = ratio_scores
    df_res["fuzz_partial"] = partial_scores
    df_res["match_score"] = df_res["fuzz_ratio"] * 0.7 + df_res["fuzz_partial"] * 0.3
    df_res = df_res[df_res["match_score"] >= threshold]
    df_res = df_res.sort_values("match_score", ascending=False).head(top_k)
    df_res["match_type"] = "Fuzzy Match"
    return df_res[["name", "generic_name", "match_type", "match_score", "fuzz_ratio"]]


def search_by_ingredient(tokens: List[str], df: pd.DataFrame) -> pd.DataFrame:
    if not tokens:
        return pd.DataFrame()
    pattern = "|".join(map(re.escape, tokens))
    mask = df["ingredient_name"].astype(str).str.contains(pattern, case=False, regex=True, na=False)
    res = df[mask].copy()
    if not res.empty:
        res["match_type"] = "Ingredient Match"

        def row_score(text: str) -> float:
            lower = str(text).lower()
            matches = sum(tok in lower for tok in tokens)
            return (matches / len(tokens)) * 100.0

        res["match_score"] = res["ingredient_name"].apply(row_score)
    return res


def hybrid_score(
    exact_score: float,
    fuzzy_score: float,
    ingredient_score: float,
    synonym_score: float,
    weights: Tuple[float, float, float, float] = DEFAULT_WEIGHTS,
) -> float:
    exact_norm = min(max(exact_score, 0.0), 1.0)
    fuzzy_norm = min(max(fuzzy_score / 100.0, 0.0), 1.0)
    ingredient_norm = min(max(ingredient_score, 0.0), 1.0)
    synonym_norm = min(max(synonym_score, 0.0), 1.0)
    w_exact, w_fuzzy, w_ing, w_syn = weights
    return w_exact * exact_norm + w_fuzzy * fuzzy_norm + w_ing * ingredient_norm + w_syn * synonym_norm


def _row_score(row: pd.Series, query: str, synonym_score: float, weights: Tuple[float, float, float, float]) -> float:
    match_type = row.get("match_type", "")
    match_score = row.get("match_score", 0.0)
    match_score = 0.0 if pd.isna(match_score) else float(match_score)

    row_exact_norm = 0.0
    row_fuzzy_norm = 0.0
    row_ingredient_norm = 0.0

    if match_type == "Exact Brand":
        row_exact_norm = 1.0
        row_fuzzy_norm = 1.0
    elif match_type == "Exact Generic":
        row_exact_norm = 0.95
        row_fuzzy_norm = _name_fuzzy_norm(query, str(row.get("name", "")))
    elif match_type == "Prefix Brand":
        row_exact_norm = 0.85
        row_fuzzy_norm = _name_fuzzy_norm(query, str(row.get("name", "")))
    elif match_type == "Fuzzy Match":
        row_fuzzy_norm = min(max(match_score / 100.0, 0.0), 1.0)
    elif match_type == "Ingredient Match":
        row_ingredient_norm = min(max(match_score / 100.0, 0.0), 1.0)

    row_synonym_norm = 1.0 if synonym_score > 0 else 0.0
    return hybrid_score(
        row_exact_norm,
        row_fuzzy_norm * 100.0,
        row_ingredient_norm,
        row_synonym_norm,
        weights=weights,
    )


def retrieve(
    query: str,
    med_df: Optional[pd.DataFrame] = None,
    ing_df: Optional[pd.DataFrame] = None,
    abbrev_dict_path: Optional[Union[str, Path]] = None,
    synonym_dict_path: Optional[Union[str, Path]] = None,
    config_path: Optional[Union[str, Path]] = None,
    top_n: Optional[int] = None,
) -> pd.DataFrame:
    if med_df is None:
        med_df = load_medicine_dataset()
    if ing_df is None:
        ing_df = load_ingredient_dataset()

    cfg = _load_config_from_path(str(config_path)) if config_path else load_config()
    abbrev_dict = load_dict(str(abbrev_dict_path)) if abbrev_dict_path else load_abbreviation_dict()
    synonym_dict = load_dict(str(synonym_dict_path)) if synonym_dict_path else load_synonym_dict()

    fuzzy_res = search_fuzzy(query, med_df)
    fuzzy_score = fuzzy_res["match_score"].max() if not fuzzy_res.empty else 0.0

    exact_res = search_exact(query, med_df)
    if not exact_res.empty:
        exact_score = 1.0
    else:
        exact_score = 0.0
        if fuzzy_score < float(cfg.get("ocr_threshold", 0.6)) * 100:
            corrected = ocr_correct(query)
            if corrected != query:
                exact_res = search_exact(corrected, med_df)
                if not exact_res.empty:
                    exact_score = 1.0
                    query = corrected

    expanded = expand_abbreviation(query, abbrev_dict)
    expanded = normalize_synonyms(expanded, synonym_dict)
    tokens = decompose_query(expanded)
    ing_res = search_by_ingredient(tokens, ing_df)
    synonym_score = 1.0 if any(tok in synonym_dict for tok in tokens) else 0.0

    results = pd.concat([exact_res, fuzzy_res, ing_res], ignore_index=True).drop_duplicates()
    if results.empty:
        return pd.DataFrame(columns=["name", "generic_name", "match_type", "match_score", "final_score"])

    weights = _weights_from_config(cfg)
    results["final_score"] = results.apply(lambda row: _row_score(row, query, synonym_score, weights), axis=1)
    results["priority"] = results["match_type"].map(MATCH_PRIORITY).fillna(0).astype(int)
    results["_medicine_sort"] = results["name"].fillna("").astype(str)
    results = results.sort_values(
        ["final_score", "priority", "match_score", "_medicine_sort"],
        ascending=[False, False, False, True],
    ).drop(columns=["priority", "_medicine_sort"])
    if top_n is not None:
        results = results.head(top_n)
    return results


def retrieve_response(query: str, top_n: int = 10) -> Dict[str, object]:
    processed_query = normalize_synonyms(expand_abbreviation(query), load_synonym_dict())
    results_df = retrieve(query, top_n=top_n)
    results = []
    for _, row in results_df.head(top_n).iterrows():
        score = row.get("final_score", row.get("match_score", 0.0))
        results.append(
            {
                "medicine": row.get("name", ""),
                "generic_name": None if pd.isna(row.get("generic_name")) else row.get("generic_name"),
                "score": float(score) if pd.notna(score) else 0.0,
                "match_type": row.get("match_type", ""),
            }
        )
    return {"query": query, "normalized_query": processed_query, "results": results}
