import pandas as pd
import time
import json
import re

# Load MedScan components
abbrev_dict = {
    'pcm': 'paracetamol',
    'amox': 'amoxicillin',
    'clav': 'clavulanic acid',
    'azithro': 'azithromycin',
    'ibupro': 'ibuprofen'
}

def expand_abbreviation(query):
    tokens = query.split()
    return ' '.join([abbrev_dict.get(tok.lower(), tok) for tok in tokens])

synonym_dict = {
    'acetaminophen': 'paracetamol',
    'dolo': 'paracetamol',
    'augmentin': 'amoxicillin clavulanic acid',
    'tylenol': 'paracetamol',
    'zithromax': 'azithromycin'
}

def normalize_synonyms(query):
    q = query.lower()
    for syn, canonical in synonym_dict.items():
        q = re.sub(r'\b' + re.escape(syn) + r'\b', canonical, q)
    return q

COMPOUND_TERMS = [
    'amoxicillin clavulanic acid',
    'clavulanic acid',
    'sodium chloride',
]

def decompose_query(query):
    original = query
    expanded = normalize_synonyms(expand_abbreviation(query))
    tokens = []
    temp = expanded.lower()
    for term in sorted(COMPOUND_TERMS, key=len, reverse=True):
        if term in temp:
            tokens.append(term)
            temp = temp.replace(term, ' ')
    tokens.extend([t.strip() for t in temp.split() if t.strip()])
    return {
        'original': original,
        'expanded': expanded,
        'tokens': tokens
    }

OCR_RULES = [
    (r'rn', 'm'),
    (r'(?<![a-z])0(?![0-9])', 'o'),
    (r'(?<![a-z])5(?![0-9])', 's'),
]

def ocr_correct(query):
    corrected = query.lower()
    for pat, repl in OCR_RULES:
        corrected = re.sub(pat, repl, corrected)
    return corrected

queries = ["pcm", "amox clav", "paracetmol", "azitromycin"]

with open("trace_report.txt", "w") as f:
    for q in queries:
        f.write(f"--- Query: {q} ---\n")
        expanded = expand_abbreviation(q)
        f.write(f"Abbreviation Expansion: {expanded}\n")
        syn_norm = normalize_synonyms(expanded)
        f.write(f"Synonym Normalization: {syn_norm}\n")
        ocr = ocr_correct(syn_norm)
        if ocr != syn_norm:
            f.write(f"OCR Correction: {ocr}\n")
        else:
            f.write(f"OCR Correction (if applied): None\n")
        decomp = decompose_query(q)
        f.write(f"Tokenization: {decomp['tokens']}\n")
        f.write("\n")

