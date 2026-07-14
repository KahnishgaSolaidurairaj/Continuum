#!/usr/bin/env python3
"""Print target-only reference embedding stats for calibration."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_EMBEDDINGS = ROOT / "Continuum" / "MLModels" / "PhonemeReferenceEmbeddings.json"

SIMILARITY_FLOOR = 0.45
SIMILARITY_CEILING = 0.92
MINIMUM_ACCEPTABLE_SIMILARITY = 0.58
MINIMUM_ACTIVE_SPEECH_RATIO = 0.12
MINIMUM_TRIMMED_RMS = 0.008
MINIMUM_TRIMMED_DURATION_SECONDS = 0.15


def cosine_similarity(left: list[float], right: list[float]) -> float:
    """Returns cosine similarity between two equal-length vectors."""
    import numpy as np

    left_array = np.asarray(left, dtype=np.float32)
    right_array = np.asarray(right, dtype=np.float32)
    denominator = np.linalg.norm(left_array) * np.linalg.norm(right_array)
    if denominator <= 1e-8:
        return 0.0
    return float(np.dot(left_array, right_array) / denominator)


def prototype_embeddings(entry: dict) -> list[list[float]]:
    """Returns all prototype vectors for one sound entry."""
    if entry.get("embeddings"):
        return entry["embeddings"]
    return [entry["embedding"]]


def similarity_to_percent(similarity: float) -> int:
    """Maps cosine similarity to a 0-100 coaching score."""
    clamped = min(SIMILARITY_CEILING, max(SIMILARITY_FLOOR, similarity))
    normalized = (clamped - SIMILARITY_FLOOR) / (SIMILARITY_CEILING - SIMILARITY_FLOOR)
    return int(round(normalized * 100))


def display_score(target_similarity: float) -> int:
    """Mirrors the runtime reference-only score mapping without boost."""
    return similarity_to_percent(target_similarity)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--embeddings", type=Path, default=DEFAULT_EMBEDDINGS)
    args = parser.parse_args()

    with args.embeddings.open(encoding="utf-8") as handle:
        payload = json.load(handle)

    labels = sorted(payload["phonemes"].keys())
    prototypes = {label: prototype_embeddings(payload["phonemes"][label]) for label in labels}

    print(f"Embedding version: {payload.get('version', 'unknown')}")
    print(f"Scoring window: {payload.get('scoringWindowSeconds', 'unknown')}s")
    print("Prototype counts:")
    for label in labels:
        print(f"  {label}: {len(prototypes[label])}")

    print("\nTarget self-match (each prototype vs itself, should be 1.0):")
    for label in labels:
        for index, embedding in enumerate(prototypes[label], start=1):
            print(f"  {label} proto {index}: {cosine_similarity(embedding, embedding):.3f}")

    print("\nPerfect-match display score (similarity = 1.0):")
    print(f"  display = {display_score(1.0)}%")

    print("\nReference-only score examples:")
    for similarity in (0.35, 0.45, 0.55, 0.58, 0.75, 0.92):
        accepted = similarity >= MINIMUM_ACCEPTABLE_SIMILARITY
        print(
            f"  similarity {similarity:.2f} -> display {display_score(similarity)}% "
            f"({'accepted' if accepted else 'rejected'})"
        )

    print("\nSuggested runtime gates:")
    print(f"  minimumAcceptableSimilarity >= {MINIMUM_ACCEPTABLE_SIMILARITY}")
    print(f"  similarityFloor = {SIMILARITY_FLOOR}")
    print(f"  minimumActiveSpeechRatio >= {MINIMUM_ACTIVE_SPEECH_RATIO}")
    print(f"  minimumTrimmedRMS >= {MINIMUM_TRIMMED_RMS}")
    print(f"  minimumTrimmedDurationSeconds >= {MINIMUM_TRIMMED_DURATION_SECONDS}")

    print("\nSuggested coaching thresholds:")
    print("  strong >= 60%")
    print("  partial >= 35%")


if __name__ == "__main__":
    main()
