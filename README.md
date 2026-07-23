# Continuum

Continuum is a SwiftUI iPad/iPhone app for practicing English pronunciation at home. It is built for kids learning speech sounds, with a parent-facing progress view and Broca the Bear as a friendly guide.

## What it does

**Home** — Warm up, see daily goals and streaks, and jump straight into practice.

**Practice** — Pick one of 44 sounds, then work through four activities:

| Activity | What the learner does |
|----------|------------------------|
| **Sandbox** | Trace the sound with a finger |
| **Flash** | Listen to the sound and words |
| **Try** | Watch a short demo clip |
| **Test** | Say a word and get speech feedback |

Priority Sounds can be pinned at the top so therapists or parents can highlight what matters most.

**Dashboard** — Weekly summaries, practice calendar, accuracy trends, and mood tracking.

On first launch, a short in-app tour walks through the main tabs. Users can skip it at any time.

## Requirements

- Xcode with a recent iOS SDK (project targets iOS 26.5+)
- Microphone access for the Test activity
- Speech recognition runs on-device for pronunciation scoring

## Getting started

1. Clone the repo and open `Continuum.xcodeproj` in Xcode.
2. Select an iPhone or iPad simulator (or a device).
3. Build and run the **Continuum** scheme.

To see the first-launch tour again during development:

```swift
AppTourStore.resetForPreview() // DEBUG only
```

Then relaunch the app.

## Project layout

```
Continuum/
├── ContinuumApp.swift          App entry + SwiftData container
├── ContentView.swift           Root view
├── Models/                     Sounds, activities, session records
├── ViewModels/                 Test activity logic
├── Views/
│   ├── Home/                   Home screen + warm-up
│   ├── Practice/               Hub + four activity screens
│   ├── Dashboard/              Progress reports
│   ├── Onboarding/             First-launch app tour
│   └── Shared/                 Theme, players, reusable UI
├── Services/                   Audio, speech, analytics, stores
└── Resources/                  Reference audio + sound manifest
```

## Data & privacy

Practice sessions and activity engagement are stored locally with SwiftData. No account or network sign-in is required for core practice features.

## Tests

Unit tests live in `ContinuumTests/`. Run them from Xcode with **⌘U**.
