"""Query processing utilities for MedScan retrieval."""

from __future__ import annotations

import re
from typing import Dict, List, Optional

from backend.artifact_loader import load_abbreviation_dict, load_synonym_dict


OCR_RULES = [
    (r"(?<![a-z])0(?![0-9])", "o"),
    (r"(?<![a-z])1(?![0-9])", "l"),
    (r"(?<![a-z])5(?![0-9])", "s"),
    (r"(?<![a-z])8(?![0-9])", "b"),
    (r"rn", "m"),
    (r"cer", "par"),
]


def expand_abbreviation(query: str, abbrev_dict: Optional[Dict[str, str]] = None) -> str:
    if abbrev_dict is None:
        abbrev_dict = load_abbreviation_dict()
    tokens = query.split()
    expanded = [abbrev_dict.get(tok, tok) for tok in tokens]
    return " ".join(expanded)


def normalize_synonyms(query: str, synonym_dict: Optional[Dict[str, str]] = None) -> str:
    if synonym_dict is None:
        synonym_dict = load_synonym_dict()
    tokens = query.split()
    normalized = [synonym_dict.get(tok, tok) for tok in tokens]
    return " ".join(normalized)


def decompose_query(query: str) -> List[str]:
    cleaned = re.sub(r"[^a-z0-9]+", " ", query.lower())
    tokens = cleaned.split()
    return tokens


def ocr_correct(query: str) -> str:
    corrected = query.lower()
    for pattern, repl in OCR_RULES:
        corrected = re.sub(pattern, repl, corrected)
    return corrected


def process_query(
    query: str,
    abbrev_dict: Optional[Dict[str, str]] = None,
    synonym_dict: Optional[Dict[str, str]] = None,
) -> Dict[str, object]:
    normalized_query = normalize_synonyms(expand_abbreviation(query, abbrev_dict), synonym_dict)
    return {
        "original_query": query,
        "normalized_query": normalized_query,
        "tokens": decompose_query(normalized_query),
    }
