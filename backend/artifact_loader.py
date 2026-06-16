"""Cached artifact loading and in-memory dataset normalization."""

from __future__ import annotations

import json
import pickle
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict

import pandas as pd


ROOT_DIR = Path(__file__).resolve().parents[1]
RETRIEVAL_ARTIFACTS_DIR = ROOT_DIR / "retrieval_artifacts"
DATA_FINAL_DIR = ROOT_DIR / "data" / "final"

CONFIG_PATH = RETRIEVAL_ARTIFACTS_DIR / "retrieval_config.json"
ABBREVIATION_DICT_PATH = RETRIEVAL_ARTIFACTS_DIR / "abbreviation_dict.pkl"
SYNONYM_DICT_PATH = RETRIEVAL_ARTIFACTS_DIR / "synonym_dict.pkl"
MEDICINE_DATASET_PATH = DATA_FINAL_DIR / "medicine_ready_v2.csv"
INGREDIENT_DATASET_PATH = DATA_FINAL_DIR / "ingredient_master_table.csv"


@lru_cache(maxsize=1)
def load_config() -> Dict[str, Any]:
    with CONFIG_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _load_pickle_dict(path: Path) -> Dict[str, str]:
    with path.open("rb") as handle:
        return pickle.load(handle)


@lru_cache(maxsize=1)
def load_abbreviation_dict() -> Dict[str, str]:
    return _load_pickle_dict(ABBREVIATION_DICT_PATH)


@lru_cache(maxsize=1)
def load_synonym_dict() -> Dict[str, str]:
    return _load_pickle_dict(SYNONYM_DICT_PATH)


@lru_cache(maxsize=1)
def load_medicine_dataset() -> pd.DataFrame:
    medicine_df = pd.read_csv(MEDICINE_DATASET_PATH, low_memory=False)

    medicine_df["ingredient_name"] = medicine_df["composition"]
    medicine_df["corpus_standard"] = medicine_df["name"].astype(str).str.lower().str.strip()
    medicine_df["corpus_normalized"] = (
        medicine_df["name"]
        .astype(str)
        .str.lower()
        .str.replace(r"[^a-z0-9\s]", " ", regex=True)
        .str.replace(r"\s+", " ", regex=True)
        .str.strip()
    )

    return medicine_df


@lru_cache(maxsize=1)
def load_ingredient_dataset() -> pd.DataFrame:
    ingredient_df = pd.read_csv(INGREDIENT_DATASET_PATH, low_memory=False)
    ingredient_df = ingredient_df.rename(
        columns={
            "brand_name": "name",
            "ingredient": "ingredient_name",
        }
    )
    return ingredient_df
