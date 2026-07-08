#!/usr/bin/env python3
"""Diagnose why TIMIT training clips may sound empty."""

from __future__ import annotations

import io
import json
import time
from pathlib import Path

import numpy as np
import soundfile as sf
from datasets import Audio, load_dataset

LOG_PATH = Path(__file__).resolve().parents[2] / ".cursor" / "debug-fa32f0.log"
SESSION_ID = "fa32f0"
TRAINING_ROOT = Path(__file__).resolve().parents[1]


def log(hypothesis_id: str, location: str, message: str, data: dict) -> None:
    # region agent log
    payload = {
        "sessionId": SESSION_ID,
        "runId": "diagnose",
        "hypothesisId": hypothesis_id,
        "location": location,
        "message": message,
        "data": data,
        "timestamp": int(time.time() * 1000),
    }
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload) + "\n")
    # endregion


def analyze_saved_clip(path: Path) -> dict:
    audio, sample_rate = sf.read(path, dtype="float32")
    peak = float(np.max(np.abs(audio)))
    rms = float(np.sqrt(np.mean(audio**2)))
    nonzero = int(np.count_nonzero(audio))
    frame = 512
    best_start = 0
    best_rms = 0.0
    for start in range(0, max(1, len(audio) - frame), frame):
        chunk = audio[start : start + frame]
        chunk_rms = float(np.sqrt(np.mean(chunk**2)))
        if chunk_rms > best_rms:
            best_rms = chunk_rms
            best_start = start
    return {
        "path": str(path),
        "duration": len(audio) / sample_rate,
        "peak": peak,
        "rms": rms,
        "nonzero_samples": nonzero,
        "nonzero_ratio": nonzero / len(audio),
        "loudest_window_start_sec": best_start / sample_rate,
        "loudest_window_rms": best_rms,
        "first_half_rms": float(np.sqrt(np.mean(audio[: len(audio) // 2] ** 2))),
        "speech_active_ratio": float(np.mean(np.abs(audio) > (peak * 0.05 if peak > 0 else 0.001))),
    }


def main() -> int:
    sample_path = TRAINING_ROOT / "m" / "timitphones_0000.wav"
    if sample_path.exists():
        saved = analyze_saved_clip(sample_path)
        log("A", "diagnose_timit_clips.py:58", "saved_clip_metrics", saved)
        log("B", "diagnose_timit_clips.py:59", "saved_clip_silence_check", {
            "peak_near_zero": saved["peak"] < 0.001,
            "mostly_zeros": saved["nonzero_ratio"] < 0.05,
        })
        log("C", "diagnose_timit_clips.py:63", "saved_clip_padding_position", {
            "loudest_window_start_sec": saved["loudest_window_start_sec"],
            "first_half_rms": saved["first_half_rms"],
            "loudest_window_rms": saved["loudest_window_rms"],
        })

    dataset = load_dataset("IParraMartin/TIMITPhones", split="train")
    dataset = dataset.cast_column("audio", Audio(decode=False))
    for row in dataset:
        if row["phoneme"] != "m":
            continue
        raw_bytes = row["audio"]["bytes"]
        raw_audio, raw_sr = sf.read(io.BytesIO(raw_bytes), dtype="float32")
        log("D", "diagnose_timit_clips.py:78", "raw_hf_clip_metrics", {
            "duration": len(raw_audio) / raw_sr,
            "peak": float(np.max(np.abs(raw_audio))),
            "rms": float(np.sqrt(np.mean(raw_audio**2))),
            "sample_rate": raw_sr,
        })
        log("E", "diagnose_timit_clips.py:84", "raw_vs_saved_peak_compare", {
            "raw_peak": float(np.max(np.abs(raw_audio))),
            "saved_peak": saved["peak"] if sample_path.exists() else None,
            "peaks_match": abs(float(np.max(np.abs(raw_audio))) - saved["peak"]) < 1e-5
            if sample_path.exists()
            else None,
        })
        break

    print(f"Diagnostics written to {LOG_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
