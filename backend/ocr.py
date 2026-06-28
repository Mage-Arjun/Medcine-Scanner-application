"""OCR module using Tesseract via pytesseract."""

from __future__ import annotations

import base64
import io
import logging
from pathlib import Path
from typing import List, Dict

import cv2
import numpy as np
import pytesseract
from PIL import Image

logger = logging.getLogger(__name__)

TESSERACT_PATH = Path(r"C:\Program Files\Tesseract-OCR\tesseract.exe")
if TESSERACT_PATH.exists():
    pytesseract.pytesseract.tesseract_cmd = str(TESSERACT_PATH)


def _preprocess_image(pil_image: Image.Image) -> Image.Image:
    arr = np.array(pil_image.convert("RGB"))
    gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
    thresh = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, 11, 2,
    )
    return Image.fromarray(thresh)


def ocr_from_image(image_b64: str) -> List[Dict[str, object]]:
    """Decode a base64 image and return OCR text blocks with confidence."""
    # Strip data URI prefix if present (e.g. "data:image/jpeg;base64,...")
    if "," in image_b64 and image_b64.startswith("data:"):
        image_b64 = image_b64.split(",", 1)[1]

    # Size guard: reject images > 5MB base64 (~3.75MB raw)
    if len(image_b64) > 7_000_000:
        logger.warning("Image too large: %d base64 chars", len(image_b64))
        return []

    try:
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        logger.error("Failed to decode image: %s", e)
        return []

    try:
        image = _preprocess_image(image)
    except Exception as e:
        logger.warning("Preprocessing failed, using raw image: %s", e)

    try:
        data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    except Exception as e:
        logger.error("Tesseract failed: %s", e)
        return []

    blocks: List[Dict[str, object]] = []
    n = len(data["text"])

    for i in range(n):
        text = data["text"][i].strip()
        conf = int(data["conf"][i])
        if text and conf > 0:
            blocks.append({
                "text": text,
                "confidence": conf / 100.0,
                "bounding_box": {
                    "x": data["left"][i],
                    "y": data["top"][i],
                    "w": data["width"][i],
                    "h": data["height"][i],
                },
            })

    logger.info("OCR extracted %d blocks from image", len(blocks))
    return blocks
