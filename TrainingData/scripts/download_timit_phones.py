#!/usr/bin/env python3
"""Download TIMITPhones clips and sort them into Create ML training folders."""

from __future__ import annotations

import argparse
import io
import json
import time
from pathlib import Path

import librosa
import numpy as np
import soundfile as sf
from datasets import Audio, load_dataset

TARGET_SAMPLE_RATE = 44_100
MIN_SPEECH_DURATION = 0.4
TARGET_CLIP_DURATION = 1.0
TARGET_PEAK = 0.9
LOG_PATH = Path(__file__).resolve().parents[2] / ".cursor" / "debug-fa32f0.log"
SESSION_ID = "fa32f0"

STARTER_LABELS = ["m", "p", "f", "noise"]
FULL_LABELS = ["m", "p", "b", "f", "v", "i", "u", "theta", "eth", "noise"]

PHONEME_TO_LABEL = {
    "m": "m",
    "p": "p",
    "b": "b",
    "f": "f",
    "v": "v",
    "iy": "i",
    "uw": "u",
    "th": "theta",
    "dh": "eth",
}
NOISE_PHONEMES = ("h#", "pau", "epi")


def log(hypothesis_id: str, location: str, message: str, data: dict, run_id: str) -> None:
    # region agent log
    payload = {
        "sessionId": SESSION_ID,
        "runId": run_id,
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download TIMITPhones into TrainingData folders.")
    parser.add_argument("--max-per-class", type=int, default=150)
    parser.add_argument("--starter-only", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def training_root() -> Path:
    return Path(__file__).resolve().parents[1]


def label_for_phoneme(phoneme: str) -> str | None:
    if phoneme in PHONEME_TO_LABEL:
        return PHONEME_TO_LABEL[phoneme]
    if phoneme in NOISE_PHONEMES:
        return "noise"
    return None


def existing_clip_count(folder: Path) -> int:
    if not folder.exists():
        return 0
    return sum(1 for path in folder.glob("timitphones_*.wav"))


def normalize_peak(audio: np.ndarray, target_peak: float) -> np.ndarray:
    peak = float(np.max(np.abs(audio)))
    if peak < 1e-8:
        return audio
    return audio * (target_peak / peak)


def extend_to_min_duration(audio: np.ndarray, sample_rate: int, min_duration: float) -> np.ndarray:
    """Lengthen short TIMIT slices so the phoneme is easier to hear and classify."""
    target_samples = int(min_duration * sample_rate)
    if len(audio) >= target_samples:
        return audio

    stretch_rate = len(audio) / target_samples
    return librosa.effects.time_stretch(audio, rate=stretch_rate)


def speech_active_ratio(audio: np.ndarray, threshold: float = 0.05) -> float:
    peak = float(np.max(np.abs(audio)))
    if peak <= 0:
        return 0.0
    cutoff = peak * threshold
    return float(np.mean(np.abs(audio) > cutoff))


def pad_start_aligned(audio: np.ndarray, sample_rate: int, target_duration: float) -> np.ndarray:
    """Place phoneme at the start, then pad with silence to the target duration."""
    target_samples = int(target_duration * sample_rate)
    if len(audio) >= target_samples:
        return audio[:target_samples]
    pad_right = target_samples - len(audio)
    return np.pad(audio, (0, pad_right), mode="constant")


def prepare_clip(audio_bytes: bytes, label: str, run_id: str, log_sample: bool) -> np.ndarray:
    audio, sample_rate = sf.read(io.BytesIO(audio_bytes), dtype="float32", always_2d=False)
    if audio.ndim > 1:
        audio = np.mean(audio, axis=1)

    raw_peak = float(np.max(np.abs(audio)))
    raw_duration = len(audio) / sample_rate

    if sample_rate != TARGET_SAMPLE_RATE:
        audio = librosa.resample(audio, orig_sr=sample_rate, target_sr=TARGET_SAMPLE_RATE)

    audio = normalize_peak(audio, TARGET_PEAK)

    min_duration = 0.25 if label == "noise" else MIN_SPEECH_DURATION
    audio = extend_to_min_duration(audio, TARGET_SAMPLE_RATE, min_duration)
    stretched_duration = len(audio) / TARGET_SAMPLE_RATE

    audio = pad_start_aligned(audio, TARGET_SAMPLE_RATE, TARGET_CLIP_DURATION)
    speech_ratio = speech_active_ratio(audio)

    if log_sample:
        log(
            "FIX",
            "download_timit_phones.py:prepare_clip",
            "processed_clip_metrics",
            {
                "label": label,
                "raw_duration": raw_duration,
                "raw_peak": raw_peak,
                "stretched_duration": stretched_duration,
                "final_duration": len(audio) / TARGET_SAMPLE_RATE,
                "final_peak": float(np.max(np.abs(audio))),
                "final_rms": float(np.sqrt(np.mean(audio**2))),
                "first_half_rms": float(np.sqrt(np.mean(audio[: len(audio) // 2] ** 2))),
                "speech_active_ratio": speech_ratio,
            },
            run_id,
        )

    return audio


def write_clip(
    destination: Path,
    audio_bytes: bytes,
    label: str,
    overwrite: bool,
    dry_run: bool,
    run_id: str,
    log_sample: bool,
) -> bool:
    if destination.exists() and not overwrite:
        return False
    if dry_run:
        return True

    audio = prepare_clip(audio_bytes, label, run_id, log_sample)
    destination.parent.mkdir(parents=True, exist_ok=True)
    sf.write(destination, audio, TARGET_SAMPLE_RATE)
    return True


def main() -> int:
    args = parse_args()
    root = training_root()
    labels = set(STARTER_LABELS if args.starter_only else FULL_LABELS)
    run_id = "post-fix" if args.overwrite else "download"

    print(f"Training root: {root}")
    print(f"Target classes: {', '.join(sorted(labels))}")
    print(
        f"Clip shape: {MIN_SPEECH_DURATION}s stretched phoneme at start, "
        f"{TARGET_CLIP_DURATION}s total, peak-normalized"
    )

    dataset = load_dataset("IParraMartin/TIMITPhones", split="train")
    dataset = dataset.cast_column("audio", Audio(decode=False))

    if args.overwrite:
        saved_counts = {label: 0 for label in labels}
    else:
        saved_counts = {label: existing_clip_count(root / label) for label in labels}

    logged_sample = False
    for row in dataset:
        label = label_for_phoneme(row["phoneme"])
        if label is None or label not in labels:
            continue
        if saved_counts[label] >= args.max_per_class:
            continue

        destination = root / label / f"timitphones_{saved_counts[label]:04d}.wav"
        if destination.exists() and not args.overwrite:
            continue

        audio_payload = row["audio"]
        if not isinstance(audio_payload, dict) or "bytes" not in audio_payload:
            continue

        if write_clip(
            destination,
            audio_payload["bytes"],
            label,
            args.overwrite,
            args.dry_run,
            run_id,
            log_sample=not logged_sample,
        ):
            saved_counts[label] += 1
            logged_sample = True

        if all(saved_counts[label] >= args.max_per_class for label in labels):
            break

    for label in sorted(labels):
        print(f"- {label:5} {saved_counts[label]:4} clips")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
