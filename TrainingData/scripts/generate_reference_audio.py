#!/usr/bin/env python3
"""Generate isolated phoneme reference WAV files for embedding similarity scoring."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "TrainingData" / "reference_audio_config.json"
OUTPUT_DIR = ROOT / "Continuum" / "Resources" / "ReferenceAudio"
METADATA_PATH = OUTPUT_DIR / "reference_metadata.json"

# Matches AVSpeechSynthesizer rate 0.45 in SpeechSynthesisService (roughly half speed).
MAC_SAY_RATE = 120


def load_config() -> dict:
    """Loads the phoneme TTS prompt configuration."""
    with CONFIG_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


def synthesize_with_say(prompt: str, voice: str, destination: Path) -> None:
    """Renders one prompt to AIFF using macOS `say`, then converts to WAV."""
    if shutil.which("say") is None:
        raise RuntimeError("macOS `say` command is required to generate reference audio.")

    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp_dir:
        aiff_path = Path(temp_dir) / "clip.aiff"
        subprocess.run(
            ["say", "-v", voice, "-r", str(MAC_SAY_RATE), "-o", str(aiff_path), prompt],
            check=True,
        )
        audio, sample_rate = sf.read(aiff_path, dtype="float32", always_2d=False)
        if audio.ndim > 1:
            audio = np.mean(audio, axis=1)
        sf.write(destination, audio, sample_rate)


def trim_silence(audio: np.ndarray, sample_rate: int, threshold: float = 0.01) -> np.ndarray:
    """Trims leading and trailing silence below an RMS threshold."""
    window = max(256, int(sample_rate * 0.01))
    if len(audio) < window:
        return audio

    def window_rms(start: int) -> float:
        chunk = audio[start : start + window]
        return float(np.sqrt(np.mean(chunk * chunk)))

    starts = range(0, len(audio) - window, window // 2)
    active = [index for index in starts if window_rms(index) >= threshold]
    if not active:
        return audio

    first = active[0]
    last = active[-1] + window
    return audio[first:last]


def normalize_peak(audio: np.ndarray, target_peak: float) -> np.ndarray:
    """Peak-normalizes audio to the configured target."""
    peak = float(np.max(np.abs(audio))) if audio.size else 0.0
    if peak <= 1e-6:
        return audio
    return audio * (target_peak / peak)


def add_pre_roll(audio: np.ndarray, sample_rate: int, seconds: float) -> np.ndarray:
    """Adds leading silence so kids can start voicing after the countdown."""
    pre_roll = np.zeros(int(sample_rate * seconds), dtype=np.float32)
    return np.concatenate([pre_roll, audio])


def resample_if_needed(audio: np.ndarray, sample_rate: int, target_rate: int) -> tuple[np.ndarray, int]:
    """Resamples audio when the TTS engine used a different sample rate."""
    if sample_rate == target_rate:
        return audio, sample_rate
    gcd = np.gcd(sample_rate, target_rate)
    up = target_rate // gcd
    down = sample_rate // gcd
    resampled = resample_poly(audio, up, down)
    return resampled.astype(np.float32), target_rate


def process_clip(raw_audio: np.ndarray, sample_rate: int, config: dict) -> tuple[np.ndarray, int]:
    """Trims, normalizes, and adds pre-roll silence to one synthesized clip."""
    audio = trim_silence(raw_audio, sample_rate)
    audio = normalize_peak(audio, float(config["targetPeak"]))
    audio, sample_rate = resample_if_needed(audio, sample_rate, int(config["sampleRate"]))
    audio = add_pre_roll(audio, sample_rate, float(config["preRollSilenceSeconds"]))
    return audio.astype(np.float32), sample_rate


def generate_all(config: dict, output_dir: Path) -> dict:
    """Generates one WAV per phoneme and returns metadata for the app build step."""
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata = {
        "version": 1,
        "voice": config["voice"],
        "sampleRate": config["sampleRate"],
        "preRollSilenceSeconds": config["preRollSilenceSeconds"],
        "phonemes": {},
    }

    for label, phoneme_config in config["phonemes"].items():
        destination = output_dir / f"{label}.wav"
        synthesize_with_say(phoneme_config["prompt"], config["voice"], destination)

        raw_audio, sample_rate = sf.read(destination, dtype="float32", always_2d=False)
        if raw_audio.ndim > 1:
            raw_audio = np.mean(raw_audio, axis=1)

        processed, sample_rate = process_clip(raw_audio, sample_rate, config)
        sf.write(destination, processed, sample_rate)

        metadata["phonemes"][label] = {
            "prompt": phoneme_config["prompt"],
            "aggregation": phoneme_config["aggregation"],
            "referenceAudioFile": f"{label}.wav",
            "referenceDurationSeconds": len(processed) / sample_rate,
            "sampleRate": sample_rate,
            "sampleCount": len(processed),
        }
        print(
            f"Wrote {destination.name}: "
            f"{metadata['phonemes'][label]['referenceDurationSeconds']:.3f}s"
        )

    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUTPUT_DIR,
        help="Directory for generated reference WAV files.",
    )
    args = parser.parse_args()

    config = load_config()
    metadata = generate_all(config, args.output_dir)

    with METADATA_PATH.open("w", encoding="utf-8") as handle:
        json.dump(metadata, handle, indent=2)
        handle.write("\n")

    print(f"Wrote metadata to {METADATA_PATH}")


if __name__ == "__main__":
    main()
