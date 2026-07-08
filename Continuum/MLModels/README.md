Drag `PhonemeClassifier.mlmodel` here after training in Create ML.

The app looks for this exact filename:

```
PhonemeClassifier.mlmodel
```

Until the model is added, the app falls back to rule-based scoring automatically.

Recommended Create ML settings:

- Template: Sound Classification
- Window duration: 0.5 seconds
- Feature extractor: Audio Feature Print

After adding the model, build and run on a real device to test live microphone scoring.
