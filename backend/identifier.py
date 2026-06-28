"""OCR identification module for MedScan."""

from __future__ import annotations

import re
from typing import Dict, List, Tuple

from backend.retrieval_engine import retrieve_response


DOSAGE_FORM_KEYWORDS = [
    "tablet", "capsule", "syrup", "injection", "ointment", "cream",
    "drop", "suspension", "lotion", "gel", "spray", "inhaler",
    "patch", "suppository", "solution", "powder",
]

NOISE_PATTERNS = [
    re.compile(r"^(batch|mfg|exp|mrp|rs|lic(en)?ce)$", re.IGNORECASE),
    re.compile(r"^\d{1,2}[/\-]\d{2,4}$"),
    re.compile(r"^[₹$£€]"),
]

NOISE_WORDS = [
    "licence", "formulation", "storage", "dosage", "warning", "warnings",
    "side effect", "side effects",
]


def _is_noise(text: str) -> bool:
    t = text.strip()
    if len(t) < 3:
        return True
    if t.isdigit():
        return True
    for pat in NOISE_PATTERNS:
        if pat.search(t):
            return True
    lower = t.lower()
    for word in NOISE_WORDS:
        if word in lower:
            return True
    return False


def _filter_noise(blocks: List[Dict[str, object]]) -> List[Dict[str, object]]:
    return [b for b in blocks if not _is_noise(str(b.get("text", "")))]


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
    cleaned = _filter_noise(ocr_blocks)
    if not cleaned:
        all_text = _extract_all_text(ocr_blocks)
        return retrieve_response(all_text, top_n=top_n)

    sorted_blocks = sorted(
        cleaned, key=lambda b: float(b.get("confidence", 0)), reverse=True
    )

    candidates = sorted_blocks[:3]

    merged: Dict[str, tuple[float, dict]] = {}
    for block in candidates:
        text = str(block.get("text", "")).strip()
        if not text:
            continue
        confidence = float(block.get("confidence", 1.0))
        resp = retrieve_response(text, top_n=top_n)
        for result in resp.get("results", []):
            name = result.get("medicine", "")
            raw_score = result.get("score", 0.0)
            weighted = raw_score * confidence
            if name not in merged or weighted > merged[name][0]:
                merged[name] = (weighted, result)

    if merged:
        sorted_results = sorted(merged.values(), key=lambda x: x[0], reverse=True)
        results = []
        for score, result in sorted_results[:top_n]:
            result["score"] = score
            results.append(result)
        return {
            "query": " | ".join(b.get("text", "") for b in candidates),
            "normalized_query": " | ".join(b.get("text", "") for b in candidates),
            "results": results,
        }

    all_text = _extract_all_text(ocr_blocks)
    return retrieve_response(all_text, top_n=top_n)
