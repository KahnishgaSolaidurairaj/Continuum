import SwiftUI
import WebKit

/// Embeds a YouTube video and plays only the requested start/end segment.
struct YouTubeSegmentPlayerView: UIViewRepresentable {
    let clip: PronunciationVideoClip
    let playbackToken: Int
    let onReady: () -> Void
    let onSegmentFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady, onSegmentFinished: onSegmentFinished)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: "playerReady")
        configuration.userContentController.add(context.coordinator, name: "segmentFinished")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        webView.loadHTMLString(Self.playerHTML(for: clip), baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard playbackToken > 0, playbackToken != context.coordinator.lastPlaybackToken else { return }
        context.coordinator.lastPlaybackToken = playbackToken
        webView.evaluateJavaScript("playSegment();", completionHandler: nil)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "playerReady")
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "segmentFinished")
    }

    /// Builds the inline YouTube IFrame player page for a bounded clip.
    private static func playerHTML(for clip: PronunciationVideoClip) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          html, body { margin: 0; padding: 0; background: #000; height: 100%; }
          #player { width: 100%; height: 100%; }
        </style>
        </head>
        <body>
        <div id="player"></div>
        <script>
          var startTime = \(clip.startSeconds);
          var endTime = \(clip.endSeconds);
          var player = null;
          var intervalId = null;

          function clearCheck() {
            if (intervalId !== null) {
              clearInterval(intervalId);
              intervalId = null;
            }
          }

          function playSegment() {
            if (!player || !player.seekTo) { return; }
            clearCheck();
            player.seekTo(startTime, true);
            player.playVideo();
            intervalId = setInterval(function() {
              if (player.getCurrentTime() >= endTime) {
                player.pauseVideo();
                clearCheck();
                window.webkit.messageHandlers.segmentFinished.postMessage("finished");
              }
            }, 150);
          }

          function onYouTubeIframeAPIReady() {
            player = new YT.Player("player", {
              height: "100%",
              width: "100%",
              videoId: "\(clip.videoID)",
              playerVars: {
                playsinline: 1,
                rel: 0,
                modestbranding: 1,
                controls: 1,
                fs: 1
              },
              events: {
                onReady: function() {
                  window.webkit.messageHandlers.playerReady.postMessage("ready");
                }
              }
            });
          }

          var tag = document.createElement("script");
          tag.src = "https://www.youtube.com/iframe_api";
          document.head.appendChild(tag);
        </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var webView: WKWebView?
        var lastPlaybackToken = 0
        private let onReady: () -> Void
        private let onSegmentFinished: () -> Void

        init(onReady: @escaping () -> Void, onSegmentFinished: @escaping () -> Void) {
            self.onReady = onReady
            self.onSegmentFinished = onSegmentFinished
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "playerReady":
                DispatchQueue.main.async(execute: onReady)
            case "segmentFinished":
                DispatchQueue.main.async(execute: onSegmentFinished)
            default:
                break
            }
        }
    }
}
