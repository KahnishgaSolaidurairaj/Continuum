#!/usr/bin/env python3
"""Print similarity distributions for reference embeddings."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_EMBEDDINGS = ROOT / "Continuum" / "MLModels" / "PhonemeReferenceEmbeddings.json"


def cosine_similarity(left: list[float], right: list[float]) -> float:
    """Returns cosine similarity between two equal-length vectors."""
    left_array = np.asarray(left, dtype=np.float32)
    right_array = np.asarray(right, dtype=np.float32)
    denominator = np.linalg.norm(left_array) * np.linalg.norm(right_array)
    if denominator <= 1e-8:
        return 0.0
    return float(np.dot(left_array, right_array) / denominator)


def similarity_to_percent(similarity: float, floor: float = 0.35, ceiling: float = 0.92) -> int:
    """Maps cosine similarity to a 0-100 coaching score."""
    clamped = min(ceiling, max(floor, similarity))
    normalized = (clamped - floor) / (ceiling - floor)
    return int(round(normalized * 100))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--embeddings", type=Path, default=DEFAULT_EMBEDDINGS)
    args = parser.parse_args()

    with args.embeddings.open(encoding="utf-8") as handle:
        payload = json.load(handle)

    labels = sorted(payload["phonemes"].keys())
    print("Self-similarity (should be 1.0):")
    for label in labels:
        embedding = payload["phonemes"][label]["embedding"]
        print(f"  {label}: {cosine_similarity(embedding, embedding):.3f}")

    print("\nTarget vs other phonemes:")
    for target in labels:
        target_embedding = payload["phonemes"][target]["embedding"]
        ranked = []
        for label in labels:
            if label == target:
                continue
            similarity = cosine_similarity(target_embedding, payload["phonemes"][label]["embedding"])
            ranked.append((label, similarity))
        ranked.sort(key=lambda item: item[1], reverse=True)
        strongest = ranked[0]
        print(
            f"  {target}: closest other = {strongest[0]} "
            f"({strongest[1]:.3f}, {similarity_to_percent(strongest[1])}%)"
        )

    print("\nSuggested coaching thresholds:")
    print("  strong >= 60%  (~ cosine >= 0.69 with floor=0.35 ceiling=0.92)")
    print("  partial >= 35% (~ cosine >= 0.55)")


if __name__ == "__main__":
    main()
