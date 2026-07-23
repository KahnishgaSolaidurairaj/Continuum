import SwiftUI

/// Try activity: embedded YouTube clip demonstrating the target sound.
struct TryActivityView: View {
    let target: PracticeTarget

    @State private var playbackToken = 0
    @State private var playerReady = false
    @State private var segmentFinished = false
    @State private var showFullVideoPrompt = false
    @State private var playbackError = false

    private var clip: PronunciationVideoClip? {
        PronunciationVideoCatalog.clip(for: target.id)
    }

    var body: some View {
        PracticeActivityScrollLayout {
            PracticeActivityHeader(
                title: "Watch Demo",
                subtitle: "See an example",
                detail: "Watch how to say \(target.displayLabel)"
            )

            videoSection
                .padding(12)
                .practiceActivityCardStyle(borderColor: ContinuumTheme.stormBlueDeep.opacity(0.25))

            actionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PracticeActivityChrome.background(for: .tryDemo))
        .alert("Watch the full video?", isPresented: $showFullVideoPrompt) {
            Button("Open YouTube") {
                openFullVideo()
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("This opens the complete pronunciation guide with all 44 English sounds on YouTube.")
        }
    }

    @ViewBuilder
    private var videoSection: some View {
        if let clip {
            ZStack {
                YouTubeSegmentPlayerView(
                    clip: clip,
                    playbackToken: playbackToken,
                    onReady: {
                        playerReady = true
                        playbackError = false
                    },
                    onSegmentFinished: { segmentFinished = true },
                    onPlaybackError: { playbackError = true }
                )

                if playbackError {
                    playbackErrorOverlay
                } else if !playerReady {
                    videoLoadingOverlay
                } else if playbackToken == 0 {
                    playOverlay
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 360)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            missingClipCard
        }
    }

    private var videoLoadingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.4)
                .tint(ContinuumTheme.stormBlueDeep)

            Text("Loading video…")
                .font(ContinuumTheme.kidSectionHeaderFont)
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }

    private var playOverlay: some View {
        Button {
            segmentFinished = false
            playbackToken += 1
        } label: {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.white)
                .shadow(color: ContinuumTheme.stormBlueDeep.opacity(0.45), radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play example clip")
    }

    private var playbackErrorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(ContinuumTheme.stormBlueDeep)

            Text("Couldn't play inside the app")
                .font(ContinuumTheme.kidSectionHeaderFont)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button {
                showFullVideoPrompt = true
            } label: {
                Text("Watch on YouTube")
                    .font(ContinuumTheme.kidButtonFont)
                    .foregroundStyle(ContinuumTheme.stormBlueDeep)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.72))
    }

    private var missingClipCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(ContinuumTheme.stormBlueDeep)

            Text("Video clip coming soon")
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.pencilLead)

            Text("We still need the timestamp for \(target.displayLabel) from the pronunciation guide.")
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 360)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if clip != nil, segmentFinished {
            VStack(spacing: 12) {
                PracticeSecondaryButton(
                    title: "Replay clip",
                    systemImage: "arrow.counterclockwise.circle.fill",
                    accent: ContinuumTheme.tabPurple
                ) {
                    segmentFinished = false
                    playbackToken += 1
                }

                PracticePrimaryButton(
                    title: "Watch full video",
                    systemImage: "arrow.up.right.square",
                    accent: ContinuumTheme.stormBlueDeep
                ) {
                    showFullVideoPrompt = true
                }
            }
        } else if clip != nil, (playerReady || playbackError), playbackToken == 0, !playbackError {
            PracticePrimaryButton(
                title: "Play clip",
                systemImage: "play.fill",
                accent: ContinuumTheme.stormBlueDeep
            ) {
                segmentFinished = false
                playbackToken += 1
            }
        } else if clip != nil, playbackError {
            PracticePrimaryButton(
                title: "Open in YouTube",
                systemImage: "arrow.up.right.square",
                accent: ContinuumTheme.stormBlueDeep
            ) {
                showFullVideoPrompt = true
            }
        } else if clip == nil {
            PracticePrimaryButton(
                title: "Open pronunciation guide",
                systemImage: "arrow.up.right.square",
                accent: ContinuumTheme.stormBlueDeep
            ) {
                showFullVideoPrompt = true
            }
        }
    }

    /// Opens the shared YouTube guide, starting at the clip when available.
    private func openFullVideo() {
        let url = clip?.fullVideoURLAtClip ?? URL(string: "https://www.youtube.com/watch?v=\(PronunciationVideoCatalog.sharedVideoID)")!
        UIApplication.shared.open(url)
    }
}
