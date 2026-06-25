"""Tests for retrieval engine."""

from __future__ import annotations

from unittest.mock import patch

import pandas as pd
import pytest

from backend.retrieval_engine import (
    _name_fuzzy_norm,
    _normalize_text,
    _row_score,
    _weights_from_config,
    hybrid_score,
    search_by_ingredient,
    search_exact,
    search_fuzzy,
)


@pytest.fixture
def med_df():
    return pd.DataFrame({
        "name": ["Crocin Advance", "Dolo 650", "Augmentin 625 Duo", "Azithral 500"],
        "generic_name": ["Paracetamol", "Paracetamol", "Amoxicillin", "Azithromycin"],
        "composition": ["Paracetamol (500mg)", "Paracetamol (650mg)", "Amoxicillin (500mg)", "Azithromycin (500mg)"],
        "ingredient_name": ["Paracetamol (500mg)", "Paracetamol (650mg)", "Amoxicillin (500mg)", "Azithromycin (500mg)"],
        "corpus_standard": ["crocin advance", "dolo 650", "augmentin 625 duo", "azithral 500"],
        "corpus_normalized": ["crocin advance", "dolo 650", "augmentin 625 duo", "azithral 500"],
        "uses": ["Pain relief", "Fever", "Infection", "Infection"],
        "side_effects": ["Nausea", "Dizziness", "Rash", "Diarrhea"],
        "image_url": [
            "https://example.com/crocin.png",
            "https://example.com/dolo.png",
            "https://example.com/augmentin.png",
            "https://example.com/azithral.png",
        ],
    })


@pytest.fixture
def ing_df():
    return pd.DataFrame({
        "medicine_id": [1, 2, 3, 4],
        "name": ["Crocin Advance", "Dolo 650", "Augmentin 625 Duo", "Azithral 500"],
        "ingredient_name": ["Paracetamol", "Paracetamol", "Amoxicillin", "Azithromycin"],
        "strength": ["500mg", "650mg", "500mg", "500mg"],
        "unit": ["mg", "mg", "mg", "mg"],
        "flag": ["", "", "", ""],
    })


class TestNormalizeText:
    def test_lowercase(self):
        assert _normalize_text("ABC") == "abc"

    def test_remove_special_chars(self):
        assert _normalize_text("para-cetamol!") == "para cetamol"

    def test_collapse_whitespace(self):
        assert _normalize_text("para   cetamol") == "para cetamol"

    def test_strip(self):
        assert _normalize_text("  paracetamol  ") == "paracetamol"

    def test_empty_string(self):
        assert _normalize_text("") == ""


class TestSearchExact:
    def test_exact_brand_match(self, med_df):
        res = search_exact("crocin advance", med_df)
        assert not res.empty
        assert res.iloc[0]["match_type"] == "Exact Brand"

    def test_exact_generic_match(self, med_df):
        res = search_exact("paracetamol", med_df)
        assert not res.empty
        assert res.iloc[0]["match_type"] == "Exact Generic"

    def test_prefix_match(self, med_df):
        res = search_exact("crocin", med_df)
        assert not res.empty
        assert res.iloc[0]["match_type"] == "Prefix Brand"

    def test_no_match(self, med_df):
        res = search_exact("nonexistent_drug_xyz", med_df)
        assert res.empty

    def test_case_insensitive(self, med_df):
        res = search_exact("CROCIN ADVANCE", med_df)
        assert not res.empty
        assert res.iloc[0]["match_type"] == "Exact Brand"


class TestSearchFuzzy:
    def test_fuzzy_match_high_score(self, med_df):
        res = search_fuzzy("crocin advance", med_df, top_k=5, threshold=50.0)
        assert not res.empty
        assert all(res["match_type"] == "Fuzzy Match")

    def test_fuzzy_match_below_threshold(self, med_df):
        res = search_fuzzy("zzzzzzz", med_df, threshold=90.0)
        assert res.empty

    def test_fuzzy_returns_all_columns(self, med_df):
        res = search_fuzzy("crocin", med_df, top_k=5, threshold=50.0)
        assert not res.empty
        assert "name" in res.columns
        assert "generic_name" in res.columns
        assert "fuzz_ratio" in res.columns
        assert "match_type" in res.columns
        assert "match_score" in res.columns
        assert "uses" in res.columns

    def test_fuzzy_empty_query(self, med_df):
        res = search_fuzzy("", med_df)
        assert res.empty


class TestSearchByIngredient:
    def test_match_ingredient(self, ing_df):
        res = search_by_ingredient(["paracetamol"], ing_df)
        assert not res.empty
        assert all(res["match_type"] == "Ingredient Match")

    def test_no_match(self, ing_df):
        res = search_by_ingredient(["zzzzzzz"], ing_df)
        assert res.empty

    def test_empty_tokens(self, ing_df):
        res = search_by_ingredient([], ing_df)
        assert res.empty

    def test_multiple_tokens(self, ing_df):
        res = search_by_ingredient(["paracetamol", "crocin"], ing_df)
        assert not res.empty


class TestHybridScore:
    def test_perfect_score(self):
        score = hybrid_score(1.0, 100.0, 1.0, 1.0)
        assert score == pytest.approx(1.0)

    def test_zero_score(self):
        score = hybrid_score(0.0, 0.0, 0.0, 0.0)
        assert score == pytest.approx(0.0)

    def test_mixed_score(self):
        weights = (0.5, 0.3, 0.1, 0.1)
        score = hybrid_score(0.5, 50.0, 0.0, 0.0, weights)
        expected = 0.5 * 0.5 + 0.3 * 0.5
        assert score == pytest.approx(expected)

    def test_clamps_values(self):
        score = hybrid_score(2.0, 200.0, 2.0, 2.0)
        assert score <= 1.0


class TestRowScore:
    def test_exact_brand_score(self, med_df):
        row = med_df.iloc[0].copy()
        row["match_type"] = "Exact Brand"
        row["match_score"] = 100.0
        weights = (0.5, 0.3, 0.1, 0.1)
        score = _row_score(row, "crocin advance", 1.0, weights)
        expected = 0.5 * 1.0 + 0.3 * 1.0 + 0.0 + 0.1 * 1.0
        assert score == pytest.approx(expected)

    def test_ingredient_match(self, ing_df):
        row = ing_df.iloc[0].copy()
        row["match_type"] = "Ingredient Match"
        row["match_score"] = 100.0
        weights = (0.5, 0.3, 0.1, 0.1)
        score = _row_score(row, "paracetamol", 0.0, weights)
        expected = 0.5 * 0.0 + 0.3 * 0.0 + 0.1 * 1.0 + 0.1 * 0.0
        assert score == pytest.approx(expected)


class TestWeightsFromConfig:
    def test_parses_config_dict(self):
        cfg = {"weights": {"exact": 0.4, "fuzzy": 0.3, "ingredient": 0.2, "synonym": 0.1}}
        w = _weights_from_config(cfg)
        assert w == (0.4, 0.3, 0.2, 0.1)

    def test_falls_back_to_defaults(self):
        w = _weights_from_config({})
        assert w == (0.5, 0.3, 0.1, 0.1)

    def test_falls_back_on_non_dict(self):
        cfg = {"weights": "invalid"}
        w = _weights_from_config(cfg)
        assert w == (0.5, 0.3, 0.1, 0.1)

    def test_partial_overrides(self):
        cfg = {"weights": {"exact": 0.6}}
        w = _weights_from_config(cfg)
        assert w[0] == 0.6
        assert w[1] == 0.3  # default


class TestNameFuzzyNorm:
    def test_perfect_match(self):
        score = _name_fuzzy_norm("crocin advance", "Crocin Advance")
        assert score == pytest.approx(1.0, abs=0.1)

    def test_no_match(self):
        score = _name_fuzzy_norm("xyz", "Crocin Advance")
        assert score < 0.5

    def test_empty_input(self):
        score = _name_fuzzy_norm("", "Crocin Advance")
        assert score == 0.0
