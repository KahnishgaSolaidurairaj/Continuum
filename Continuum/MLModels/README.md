# ML Assets for Embedding Similarity Scoring

The Test activity scores pronunciation by comparing the user's recording to bundled TTS reference clips using cosine similarity on Audio Feature Print embeddings.

## Runtime bundle (required)

| File | Purpose |
|------|---------|
| `PhonemeAudioEncoder.mlmodel` | Audio Feature Print encoder (audio → 512-d vector) |
| `PhonemeReferenceEmbeddings.json` | Precomputed reference embeddings + recording durations |
| `Resources/ReferenceAudio/*.wav` | Source reference clips (used to rebuild JSON) |

Until the encoder and JSON are present, the app falls back to rule-based scoring automatically.

## Build-time only

| File | Purpose |
|------|---------|
| `PhonemeClassifier.mlmodel` | Create ML sound classifier used once to extract the encoder |

Recommended Create ML settings for the classifier:

- Template: Sound Classification
- Window duration: 0.5 seconds
- Feature extractor: Audio Feature Print

## Regenerating references

From the repo root on macOS:

```bash
python3 TrainingData/scripts/generate_reference_audio.py
python3 TrainingData/scripts/extract_audio_encoder.py
python3 TrainingData/scripts/build_reference_embeddings.py
python3 TrainingData/scripts/calibrate_embedding_thresholds.py
```

Edit `TrainingData/reference_audio_config.json` to change TTS prompts, then rerun the scripts above. Replace any `Continuum/Resources/ReferenceAudio/*.wav` manually if a phoneme needs a human-recorded reference instead of TTS.

After updating assets, build and run on a real device to test live microphone scoring.
