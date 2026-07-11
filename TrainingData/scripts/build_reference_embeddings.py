#!/usr/bin/env python3
"""Build per-phoneme reference embeddings from bundled TTS reference audio."""

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


def load_metadata(metadata_path: Path) -> dict:
    """Loads reference audio metadata produced by generate_reference_audio.py."""
    with metadata_path.open(encoding="utf-8") as handle:
        return json.load(handle)


def resample_audio(audio: np.ndarray, sample_rate: int, target_rate: int) -> np.ndarray:
    """Resamples audio to the encoder's expected sample rate."""
    if sample_rate == target_rate:
        return audio.astype(np.float32)
    gcd = np.gcd(sample_rate, target_rate)
    up = target_rate // gcd
    down = sample_rate // gcd
    return resample_poly(audio, up, down).astype(np.float32)


def pad_or_trim(audio: np.ndarray, sample_count: int) -> np.ndarray:
    """Pads or trims audio to an exact sample count."""
    if len(audio) == sample_count:
        return audio
    if len(audio) > sample_count:
        return audio[:sample_count]
    padding = np.zeros(sample_count - len(audio), dtype=np.float32)
    return np.concatenate([audio, padding])


def prepare_encoder_input(audio: np.ndarray, sample_rate: int, sample_count: int) -> np.ndarray:
    """Resamples and sizes one clip for Audio Feature Print inference."""
    resampled = resample_audio(audio, sample_rate, ENCODER_SAMPLE_RATE)
    target_samples = max(MIN_ENCODER_SAMPLES, sample_count)
    target_samples = int(round(target_samples * ENCODER_SAMPLE_RATE / sample_rate))
    return pad_or_trim(resampled, target_samples)


def predict_embedding(model: ct.models.MLModel, audio: np.ndarray) -> list[float]:
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
    return [float(value) for value in vector]


def build_embeddings(
    metadata: dict,
    reference_dir: Path,
    encoder_path: Path,
) -> dict:
    """Embeds each reference clip and returns app-ready metadata."""
    if not encoder_path.exists():
        raise FileNotFoundError(
            f"Encoder not found at {encoder_path}. Run extract_audio_encoder.py first."
        )

    model = ct.models.MLModel(str(encoder_path))
    output = {
        "version": 2,
        "embeddingSize": 512,
        "voice": metadata.get("voice", "en-US"),
        "encoderSampleRate": ENCODER_SAMPLE_RATE,
        "phonemes": {},
    }

    for label, phoneme_metadata in metadata["phonemes"].items():
        wav_path = reference_dir / phoneme_metadata["referenceAudioFile"]
        audio, sample_rate = sf.read(wav_path, dtype="float32", always_2d=False)
        if audio.ndim > 1:
            audio = np.mean(audio, axis=1)

        prepared = prepare_encoder_input(
            audio,
            sample_rate,
            int(phoneme_metadata["sampleCount"]),
        )
        embedding = predict_embedding(model, prepared)

        output["phonemes"][label] = {
            "embedding": embedding,
            "referenceDurationSeconds": phoneme_metadata["referenceDurationSeconds"],
            "referenceAudioFile": phoneme_metadata["referenceAudioFile"],
            "sampleRate": phoneme_metadata["sampleRate"],
            "sampleCount": phoneme_metadata["sampleCount"],
            "aggregation": phoneme_metadata.get("aggregation", "sustained"),
        }
        print(f"Embedded {label}: {len(embedding)} dims")

    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata", type=Path, default=METADATA_PATH)
    parser.add_argument("--reference-dir", type=Path, default=REFERENCE_DIR)
    parser.add_argument("--encoder", type=Path, default=DEFAULT_ENCODER)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    metadata = load_metadata(args.metadata)
    embeddings = build_embeddings(metadata, args.reference_dir, args.encoder)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        json.dump(embeddings, handle, indent=2)
        handle.write("\n")

    print(f"Wrote embeddings to {args.output}")


if __name__ == "__main__":
    main()
