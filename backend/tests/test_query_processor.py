"""Tests for query processing utilities."""

from __future__ import annotations

import pytest

from backend.query_processor import (
    decompose_query,
    expand_abbreviation,
    normalize_synonyms,
    ocr_correct,
    process_query,
)


class TestOcrCorrect:
    def test_removes_bad_i_to_l_rule(self):
        assert ocr_correct("ibuprofen") == "ibuprofen"

    def test_rn_to_m(self):
        assert ocr_correct("medicrne") == "medicme"

    def test_0_to_o(self):
        assert ocr_correct("med0cine") == "medocine"

    def test_1_to_l(self):
        assert ocr_correct("med1cine") == "medlcine"

    def test_5_to_s(self):
        assert ocr_correct("med5ine") == "medsine"

    def test_multiple_rules(self):
        assert ocr_correct("C0rn5") == "coms"

    def test_no_change_for_clean_input(self):
        assert ocr_correct("paracetamol") == "paracetamol"

    def test_empty_string(self):
        assert ocr_correct("") == ""

    def test_only_special_chars(self):
        assert ocr_correct("123!@#") == "l23!@#"


class TestExpandAbbreviation:
    def test_known_abbreviation(self):
        d = {"pcm": "paracetamol"}
        assert expand_abbreviation("pcm", d) == "paracetamol"

    def test_unknown_token_preserved(self):
        d = {"pcm": "paracetamol"}
        assert expand_abbreviation("aspirin", d) == "aspirin"

    def test_mixed_known_and_unknown(self):
        d = {"pcm": "paracetamol", "tab": "tablet"}
        assert expand_abbreviation("pcm tab", d) == "paracetamol tablet"

    def test_empty_abbrev_dict(self):
        assert expand_abbreviation("hello world", {}) == "hello world"

    def test_empty_query(self):
        assert expand_abbreviation("", {}) == ""


class TestNormalizeSynonyms:
    def test_known_synonym(self):
        d = {"tylenol": "paracetamol"}
        assert normalize_synonyms("tylenol", d) == "paracetamol"

    def test_unknown_token_preserved(self):
        d = {"tylenol": "paracetamol"}
        assert normalize_synonyms("ibuprofen", d) == "ibuprofen"

    def test_mixed_known_and_unknown(self):
        d = {"tylenol": "paracetamol", "advil": "ibuprofen"}
        assert normalize_synonyms("tylenor advil", d) == "tylenor ibuprofen"

    def test_empty_synonym_dict(self):
        assert normalize_synonyms("hello world", {}) == "hello world"

    def test_empty_query(self):
        assert normalize_synonyms("", {}) == ""


class TestDecomposeQuery:
    def test_simple_query(self):
        assert decompose_query("paracetamol") == ["paracetamol"]

    def test_multiple_tokens(self):
        assert decompose_query("paracetamol   tablet") == ["paracetamol", "tablet"]

    def test_strips_punctuation(self):
        assert decompose_query("para-cetamol!") == ["para", "cetamol"]

    def test_lowercases(self):
        assert decompose_query("ParaCetamol") == ["paracetamol"]

    def test_empty_string(self):
        assert decompose_query("") == []

    def test_only_special_chars(self):
        assert decompose_query("!@#$") == []


class TestProcessQuery:
    def test_full_pipeline(self):
        abbrev = {"pcm": "paracetamol"}
        synonym = {}
        result = process_query("pcm", abbrev, synonym)
        assert result["original_query"] == "pcm"
        assert result["normalized_query"] == "paracetamol"
        assert result["tokens"] == ["paracetamol"]

    def test_whitespace_handling(self):
        abbrev = {}
        synonym = {}
        result = process_query("  paracetamol  ", abbrev, synonym)
        assert result["normalized_query"] == "paracetamol"
        assert result["tokens"] == ["paracetamol"]

    def test_default_args(self):
        result = process_query("paracetamol")
        assert result["original_query"] == "paracetamol"
