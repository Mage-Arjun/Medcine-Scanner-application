"""OCR identification module for MedScan."""

from __future__ import annotations

from typing import Dict, List, Optional

from backend.retrieval_engine import retrieve_response


DOSAGE_FORM_KEYWORDS = [
    "tablet", "capsule", "syrup", "injection", "ointment", "cream",
    "drop", "suspension", "lotion", "gel", "spray", "inhaler",
    "patch", "suppository", "solution", "powder",
]


def _rank_blocks_by_size(blocks: List[Dict[str, object]]) -> List[Dict[str, object]]:
    return sorted(blocks, key=lambda b: len(str(b.get("text", ""))), reverse=True)


def _extract_candidate_text(blocks: List[Dict[str, object]]) -> str:
    if not blocks:
        return ""
    ranked = _rank_blocks_by_size(blocks)
    for block in ranked:
        text = str(block.get("text", ""))
        if any(kw in text.lower() for kw in DOSAGE_FORM_KEYWORDS):
            return text
    for block in ranked:
        text = str(block.get("text", ""))
        if len(text) > 3 and text.isupper():
            return text
    return str(ranked[0].get("text", ""))


def _extract_all_text(blocks: List[Dict[str, object]]) -> str:
    return " ".join(str(b.get("text", "")) for b in blocks)


def identify(
    ocr_blocks: List[Dict[str, object]],
    top_n: int = 5,
) -> Dict[str, object]:
    candidate = _extract_candidate_text(ocr_blocks)
    all_text = _extract_all_text(ocr_blocks)
    query = candidate if candidate else all_text
    return retrieve_response(query, top_n=top_n)
