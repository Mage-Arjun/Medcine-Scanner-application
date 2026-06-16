"""Compatibility layer for Day 4 notebooks.

Production retrieval logic now lives under ``backend``. This module preserves
the original import path and function names used by existing notebooks.
"""

from backend.query_processor import (  # noqa: F401
    decompose_query,
    expand_abbreviation,
    normalize_synonyms,
    ocr_correct,
    process_query,
)
from backend.retrieval_engine import (  # noqa: F401
    hybrid_score,
    load_dict,
    retrieve,
    search_by_ingredient,
    search_exact,
    search_fuzzy,
)
