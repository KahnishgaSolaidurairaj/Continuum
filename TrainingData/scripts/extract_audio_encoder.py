#!/usr/bin/env python3
"""Extract the Audio Feature Print encoder from a Create ML sound classifier."""

from __future__ import annotations

import argparse
from pathlib import Path

import coremltools as ct
from coremltools.models.utils import save_spec

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CLASSIFIER = ROOT / "Continuum" / "MLModels" / "PhonemeClassifier.mlmodel"
DEFAULT_ENCODER = ROOT / "Continuum" / "MLModels" / "PhonemeAudioEncoder.mlmodel"


def extract_encoder(classifier_path: Path, encoder_path: Path) -> None:
    """Saves the first Audio Feature Print stage as a standalone Core ML model.

    Parameters:
        classifier_path: Create ML sound classifier export.
        encoder_path: Destination path for the embedding-only model.
    """
    if not classifier_path.exists():
        raise FileNotFoundError(
            f"Classifier not found at {classifier_path}. Train in Create ML first."
        )

    spec = ct.models.MLModel(str(classifier_path)).get_spec()
    model_type = spec.WhichOneof("Type")
    if model_type != "pipelineClassifier":
        raise ValueError(f"Expected pipelineClassifier, found {model_type}.")

    pipeline = spec.pipelineClassifier.pipeline
    if not pipeline.models:
        raise ValueError("Classifier pipeline does not contain any sub-models.")

    encoder_spec = pipeline.models[0]
    if encoder_spec.WhichOneof("Type") != "audioFeaturePrint":
        raise ValueError(
            f"Expected audioFeaturePrint as first stage, found {encoder_spec.WhichOneof('Type')}."
        )

    encoder_path.parent.mkdir(parents=True, exist_ok=True)
    save_spec(encoder_spec, str(encoder_path))

    outputs = [output.name for output in encoder_spec.description.output]
    sample_rate = encoder_spec.description.metadata.userDefined.get("sampleRate", "unknown")
    print(f"Saved encoder to {encoder_path}")
    print(f"Outputs: {outputs}")
    print(f"Sample rate: {sample_rate}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classifier", type=Path, default=DEFAULT_CLASSIFIER)
    parser.add_argument("--encoder", type=Path, default=DEFAULT_ENCODER)
    args = parser.parse_args()
    extract_encoder(args.classifier, args.encoder)


if __name__ == "__main__":
    main()
