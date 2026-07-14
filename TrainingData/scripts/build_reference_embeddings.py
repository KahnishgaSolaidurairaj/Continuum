#!/usr/bin/env python3
"""Build multi-prototype reference embeddings from bundled Flash playback clips."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import coremltools as ct
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

ROOT = Path(__file__).resolve().parents[2]
REFERENCE_DIR = ROOT / "Continuum" / "Resources" / "ReferenceAudio"
METADATA_PATH = REFERENCE_DIR / "reference_metadata.json"
DEFAULT_ENCODER = ROOT / "Continuum" / "MLModels" / "PhonemeAudioEncoder.mlmodel"
DEFAULT_OUTPUT = ROOT / "Continuum" / "MLModels" / "PhonemeReferenceEmbeddings.json"

ENCODER_SAMPLE_RATE = 16_000
MIN_ENCODER_SAMPLES = 8_000
TRIM_THRESHOLD = 0.01
TARGET_PEAK = 0.9
SCORING_WINDOW_SECONDS = 1.0


def load_metadata(metadata_path: Path) -> dict:
    """Loads reference audio metadata produced by ingest."""
    with metadata_path.open(encoding="utf-8") as handle:
        return json.load(handle)


def trim_silence(audio: np.ndarray, sample_rate: int, threshold: float = TRIM_THRESHOLD) -> np.ndarray:
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


def normalize_peak(audio: np.ndarray, target_peak: float = TARGET_PEAK) -> np.ndarray:
    """Peak-normalizes audio to the configured target."""
    peak = float(np.max(np.abs(audio))) if audio.size else 0.0
    if peak <= 1e-6:
        return audio
    return audio * (target_peak / peak)


def resample_audio(audio: np.ndarray, sample_rate: int, target_rate: int) -> np.ndarray:
    """Resamples audio to the encoder's expected sample rate."""
    if sample_rate == target_rate:
        return audio.astype(np.float32)
    gcd = np.gcd(sample_rate, target_rate)
    up = target_rate // gcd
    down = sample_rate // gcd
    return resample_poly(audio, up, down).astype(np.float32)


def center_in_fixed_window(audio: np.ndarray, target_count: int) -> np.ndarray:
    """Centers audio in a fixed window with silence padding on both sides."""
    if target_count <= 0:
        return audio
    if len(audio) == target_count:
        return audio
    if len(audio) > target_count:
        start = (len(audio) - target_count) // 2
        return audio[start : start + target_count]

    padding = target_count - len(audio)
    leading = padding // 2
    trailing = padding - leading
    return np.concatenate(
        [
            np.zeros(leading, dtype=np.float32),
            audio,
            np.zeros(trailing, dtype=np.float32),
        ]
    )


def prepare_scoring_encoder_input(audio: np.ndarray, sample_rate: int) -> np.ndarray:
    """Centers one clip in a 1s window, resamples, and sizes for encoder inference."""
    source_window_count = int(round(sample_rate * SCORING_WINDOW_SECONDS))
    centered = center_in_fixed_window(audio.astype(np.float32), source_window_count)
    resampled = resample_audio(centered, sample_rate, ENCODER_SAMPLE_RATE)
    encoder_window_count = max(
        MIN_ENCODER_SAMPLES,
        int(round(ENCODER_SAMPLE_RATE * SCORING_WINDOW_SECONDS)),
    )
    return center_in_fixed_window(resampled, encoder_window_count)


def predict_embedding(model: ct.models.MLModel, audio: np.ndarray) -> np.ndarray:
    """Runs the encoder and returns a 512-dimensional embedding."""
    input_array = np.expand_dims(audio.astype(np.float32), axis=0)
    prediction = model.predict({"audioSamples": input_array})
    features = prediction["features"]
    if hasattr(features, "tolist"):
        vector = features.tolist()
    else:
        vector = list(features)
    if vector and isinstance(vector[0], list):
        vector = vector[0]
    return np.asarray(vector, dtype=np.float32)


def l2_normalize(vector: np.ndarray) -> np.ndarray:
    """Returns a unit-length copy of one embedding vector."""
    norm = float(np.linalg.norm(vector))
    if norm <= 1e-8:
        return vector
    return vector / norm


def embed_clip(model: ct.models.MLModel, wav_path: Path) -> tuple[list[float], int]:
    """Embeds one bundled WAV clip after trim, normalize, and centered 1s scoring window."""
    audio, sample_rate = sf.read(wav_path, dtype="float32", always_2d=False)
    if audio.ndim > 1:
        audio = np.mean(audio, axis=1)

    trimmed = trim_silence(audio.astype(np.float32), int(sample_rate))
    trimmed = normalize_peak(trimmed)
    scoring_window_count = int(round(sample_rate * SCORING_WINDOW_SECONDS))

    prepared = prepare_scoring_encoder_input(trimmed, int(sample_rate))
    embedding = l2_normalize(predict_embedding(model, prepared)).astype(float).tolist()
    return embedding, scoring_window_count


def build_embeddings(metadata: dict, reference_dir: Path, encoder_path: Path) -> dict:
    """Embeds every clip variant listed in reference metadata."""
    if not encoder_path.exists():
        raise FileNotFoundError(
            f"Encoder not found at {encoder_path}. Run extract_audio_encoder.py first."
        )

    model = ct.models.MLModel(str(encoder_path))
    output = {
        "version": 7,
        "embeddingSize": 512,
        "voice": "PhonemeAudio",
        "encoderSampleRate": ENCODER_SAMPLE_RATE,
        "scoringWindowSeconds": SCORING_WINDOW_SECONDS,
        "targetDurationSeconds": SCORING_WINDOW_SECONDS,
        "phonemes": {},
    }

    for label, phoneme_metadata in metadata["phonemes"].items():
        clip_files = phoneme_metadata.get("clipFiles") or [
            phoneme_metadata.get("playbackFile") or phoneme_metadata["referenceAudioFile"]
        ]

        embeddings: list[list[float]] = []
        active_sample_counts: list[int] = []
        for clip_name in clip_files:
            wav_path = reference_dir / clip_name
            if not wav_path.exists():
                print(f"Skipping missing clip for {label}: {clip_name}")
                continue
            embedding, active_count = embed_clip(model, wav_path)
            embeddings.append(embedding)
            active_sample_counts.append(active_count)

        if not embeddings:
            raise FileNotFoundError(f"No clip files found for sound '{label}'.")

        playback_file = phoneme_metadata.get("playbackFile") or phoneme_metadata["referenceAudioFile"]
        scoring_window_count = int(round(phoneme_metadata["sampleRate"] * SCORING_WINDOW_SECONDS))

        output["phonemes"][label] = {
            "embedding": embeddings[0],
            "embeddings": embeddings,
            "prototypeCount": len(embeddings),
            "referenceDurationSeconds": SCORING_WINDOW_SECONDS,
            "referenceAudioFile": playback_file,
            "sampleRate": phoneme_metadata["sampleRate"],
            "sampleCount": phoneme_metadata["sampleCount"],
            "activeSampleCount": scoring_window_count,
            "activeSampleCounts": active_sample_counts,
            "activeDurationSeconds": SCORING_WINDOW_SECONDS,
            "aggregation": "centered_one_second",
        }
        print(
            f"Embedded {label}: {len(embeddings)} prototypes "
            f"(scoring window {SCORING_WINDOW_SECONDS:.1f}s)"
        )

    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata", type=Path, default=METADATA_PATH)
    parser.add_argument("--reference-dir", type=Path, default=REFERENCE_DIR)
    parser.add_argument("--encoder", type=Path, default=DEFAULT_ENCODER)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    metadata = load_metadata(args.metadata)
    payload = build_embeddings(metadata, args.reference_dir, args.encoder)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")

    print(f"Wrote {args.output} with {len(payload['phonemes'])} sounds.")


if __name__ == "__main__":
    main()
