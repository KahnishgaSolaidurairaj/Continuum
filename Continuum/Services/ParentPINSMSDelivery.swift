import MessageUI
import SwiftUI
import UIKit

/// Presents the system SMS composer to deliver a temporary parent PIN.
struct ParentPINSMSComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onFinish: (MessageComposeResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    /// Handles compose completion callbacks from MessageUI.
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: (MessageComposeResult) -> Void

        init(onFinish: @escaping (MessageComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
            onFinish(result)
        }
    }
}

/// Sends or opens an SMS with the temporary parent unlock code.
enum ParentPINSMSDelivery {
    /// Whether the current device can send text messages.
    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    /// Builds the recovery SMS body for a temporary parent PIN.
    /// - Parameter temporaryPIN: Six-digit code to include in the message.
    /// - Returns: SMS body text.
    static func messageBody(for temporaryPIN: String) -> String {
        "Your Continuum temporary parent PIN is \(temporaryPIN). It expires in 15 minutes."
    }

    /// Opens the Messages app with the recovery text prefilled when SMS compose is unavailable.
    /// - Parameters:
    ///   - phoneNumber: Destination phone number.
    ///   - body: SMS body text.
    /// - Returns: Whether the Messages app opened successfully.
    static func openPrefilledMessage(phoneNumber: String, body: String) -> Bool {
        let digits = phoneNumber.filter(\.isNumber)
        guard !digits.isEmpty,
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "sms:\(digits)&body=\(encodedBody)") else {
            return false
        }
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
