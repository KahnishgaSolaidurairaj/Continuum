import SwiftUI
import WebKit

/// Embeds a YouTube video and plays only the requested start/end segment.
struct YouTubeSegmentPlayerView: UIViewRepresentable {
    let clip: PronunciationVideoClip
    let playbackToken: Int
    let onReady: () -> Void
    let onSegmentFinished: () -> Void
    let onPlaybackError: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady, onSegmentFinished: onSegmentFinished, onPlaybackError: onPlaybackError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: "playerReady")
        configuration.userContentController.add(context.coordinator, name: "segmentFinished")
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = Self.safariUserAgent
        context.coordinator.webView = webView
        webView.loadHTMLString(
            Self.playerHTML(for: clip, origin: Self.appReferrerString),
            baseURL: Self.appReferrerURL
        )
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard playbackToken > 0, playbackToken != context.coordinator.lastPlaybackToken else { return }
        context.coordinator.lastPlaybackToken = playbackToken
        webView.evaluateJavaScript("playSegment();", completionHandler: nil)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.invalidateTimer()
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "playerReady")
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "segmentFinished")
    }

    private static var appReferrerURL: URL {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.continuum.app"
        return URL(string: "https://\(bundleID.lowercased())")!
    }

    private static var appReferrerString: String {
        appReferrerURL.absoluteString
    }

    private static let safariUserAgent =
        "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    private static func playerHTML(for clip: PronunciationVideoClip, origin: String) -> String {
        let encodedOrigin = origin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? origin
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <meta name="referrer" content="strict-origin-when-cross-origin">
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
                  start: Math.floor(startTime),
                  enablejsapi: 1,
                  origin: "\(encodedOrigin)"
                },
                events: {
                  onReady: function() {
                    window.webkit.messageHandlers.playerReady.postMessage("ready");
                  },
                  onError: function() {
                    window.webkit.messageHandlers.segmentFinished.postMessage("error");
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
        private let onPlaybackError: () -> Void
        private var segmentTimer: Timer?

        init(
            onReady: @escaping () -> Void,
            onSegmentFinished: @escaping () -> Void,
            onPlaybackError: @escaping () -> Void
        ) {
            self.onReady = onReady
            self.onSegmentFinished = onSegmentFinished
            self.onPlaybackError = onPlaybackError
        }

        func invalidateTimer() {
            segmentTimer?.invalidate()
            segmentTimer = nil
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "playerReady":
                DispatchQueue.main.async(execute: onReady)
            case "segmentFinished":
                if message.body as? String == "error" {
                    DispatchQueue.main.async(execute: onPlaybackError)
                } else {
                    DispatchQueue.main.async(execute: onSegmentFinished)
                }
            default:
                break
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async(execute: onPlaybackError)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            DispatchQueue.main.async(execute: onPlaybackError)
        }
    }
}
