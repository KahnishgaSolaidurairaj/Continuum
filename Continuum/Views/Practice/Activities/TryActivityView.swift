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
        VStack(spacing: 20) {
            Text("See an example")
                .font(ContinuumTheme.kidSectionHeaderFont)
                .foregroundStyle(ContinuumTheme.stormBlueDeep)

            Text("Watch how to say \(target.displayLabel)")
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.stormBlueDeep)
                .multilineTextAlignment(.center)

            videoSection

            actionButtons
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [ContinuumTheme.homeLavender, ContinuumTheme.stormBlue],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
                    ProgressView("Loading video…")
                        .tint(ContinuumTheme.stormBlueDeep)
                        .foregroundStyle(ContinuumTheme.stormBlueDeep)
                } else if playbackToken == 0 {
                    playOverlay
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ContinuumTheme.stormBlueDeep, lineWidth: 2)
            )
        } else {
            missingClipCard
        }
    }

    private var playOverlay: some View {
        Button {
            segmentFinished = false
            playbackToken += 1
        } label: {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .shadow(color: ContinuumTheme.stormBlueDeep.opacity(0.45), radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play example clip")
    }

    private var playbackErrorOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)

            Text("Couldn't play inside the app")
                .font(ContinuumTheme.kidSubheadFont)
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
                .foregroundStyle(ContinuumTheme.stormBlueDeep)

            Text("We still need the timestamp for \(target.displayLabel) from the pronunciation guide.")
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(ContinuumTheme.stormBlueDeep.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ContinuumTheme.stormBlueDeep, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var actionButtons: some View {
        if clip != nil, segmentFinished {
            VStack(spacing: 12) {
                Button {
                    segmentFinished = false
                    playbackToken += 1
                } label: {
                    Label("Replay clip", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(ContinuumTheme.kidButtonFont)
                        .foregroundStyle(ContinuumTheme.stormBlueDeep)
                        .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                        .background(ContinuumTheme.lightningGlow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ContinuumTheme.stormBlueDeep, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    showFullVideoPrompt = true
                } label: {
                    Label("Watch full video", systemImage: "arrow.up.right.square")
                        .font(ContinuumTheme.kidButtonFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                        .background(ContinuumTheme.stormBlueDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        } else if clip != nil, (playerReady || playbackError), playbackToken == 0, !playbackError {
            Button {
                segmentFinished = false
                playbackToken += 1
            } label: {
                Label("Play clip", systemImage: "play.fill")
                    .font(ContinuumTheme.kidButtonFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                    .background(ContinuumTheme.stormBlueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        } else if clip != nil, playbackError {
            Button {
                showFullVideoPrompt = true
            } label: {
                Label("Open in YouTube", systemImage: "arrow.up.right.square")
                    .font(ContinuumTheme.kidButtonFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                    .background(ContinuumTheme.stormBlueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        } else if clip == nil {
            Button {
                showFullVideoPrompt = true
            } label: {
                Label("Open pronunciation guide", systemImage: "arrow.up.right.square")
                    .font(ContinuumTheme.kidButtonFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                    .background(ContinuumTheme.stormBlueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    /// Opens the shared YouTube guide, starting at the clip when available.
    private func openFullVideo() {
        let url = clip?.fullVideoURLAtClip ?? URL(string: "https://www.youtube.com/watch?v=\(PronunciationVideoCatalog.sharedVideoID)")!
        UIApplication.shared.open(url)
    }
}
