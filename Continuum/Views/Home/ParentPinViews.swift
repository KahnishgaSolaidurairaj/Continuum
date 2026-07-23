import SwiftUI

/// Four-digit PIN entry used for setup, reset, and parent unlock flows.
struct ParentPINDigitEntryView: View {
    @Binding var pin: String
    let title: String
    let subtitle: String
    var pinLength: Int = 4
    var errorMessage: String? = nil
    var statusMessage: String? = nil

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(ContinuumTheme.kidSectionHeaderFont)
                .foregroundStyle(ContinuumTheme.testMagenta)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)

            if let statusMessage {
                Text(statusMessage)
                    .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                    .foregroundStyle(ContinuumTheme.homeMintText)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? ContinuumTheme.testMagenta : Color.white)
                        .frame(width: pinLength > 4 ? 14 : 18, height: pinLength > 4 ? 14 : 18)
                        .overlay(
                            Circle()
                                .stroke(ContinuumTheme.testMagenta.opacity(0.45), lineWidth: 2)
                        )
                }
            }
            .accessibilityLabel("\(pin.count) of \(pinLength) digits entered")

            if let errorMessage {
                Text(errorMessage)
                    .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            pinPad
        }
    }

    private var pinPad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "delete"]

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(keys, id: \.self) { key in
                if key.isEmpty {
                    Color.clear.frame(height: 52)
                } else {
                    Button {
                        handleKeyPress(key)
                    } label: {
                        Group {
                            if key == "delete" {
                                Image(systemName: "delete.backward.fill")
                                    .font(.system(size: 20, weight: .semibold))
                            } else {
                                Text(key)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ContinuumTheme.testMagenta.opacity(0.2), lineWidth: 1.5)
                        )
                        .fullRoundedHitTarget(cornerRadius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Appends, removes, or ignores keypad input while keeping the PIN at four digits.
    private func handleKeyPress(_ key: String) {
        if key == "delete" {
            guard !pin.isEmpty else { return }
            pin.removeLast()
            return
        }

        guard pin.count < pinLength, key.allSatisfy(\.isNumber) else { return }
        pin.append(key)
    }
}

/// Sheet for parents to create or update their four-digit PIN and backup phone number.
struct ParentPINSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPIN = ""
    // @State private var backupPhone = ParentModeStore.backupPhoneNumber ?? ""
    @State private var step: SetupStep = .enterPIN
    @State private var errorMessage: String?

    private enum SetupStep {
        case enterPIN
        case confirmPIN
    }

    var body: some View {
        ZStack {
            ContinuumTheme.homePink.ignoresSafeArea()

            VStack(spacing: 20) {
                switch step {
                case .enterPIN:
                    ParentPINDigitEntryView(
                        pin: $pin,
                        title: "Create Parent PIN",
                        subtitle: "Choose a 4-digit PIN to protect parent settings.",
                        errorMessage: errorMessage
                    )
                    .onChange(of: pin) { _, newValue in
                        guard newValue.count == 4 else { return }
                        errorMessage = nil
                        step = .confirmPIN
                    }

                case .confirmPIN:
                    ParentPINDigitEntryView(
                        pin: $confirmPIN,
                        title: "Confirm Parent PIN",
                        subtitle: "Enter the same 4-digit PIN again.",
                        errorMessage: errorMessage
                    )
                    .onChange(of: confirmPIN) { _, newValue in
                        guard newValue.count == 4 else { return }
                        savePIN()
                    }
                }

                /*
                VStack(alignment: .leading, spacing: 8) {
                    Text("Backup phone number")
                        .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                        .foregroundStyle(ContinuumTheme.testMagenta)

                    TextField("For PIN reset", text: $backupPhone)
                        .keyboardType(.phonePad)
                        .font(ContinuumTheme.kidBodyFont)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                */

                HStack(spacing: 12) {
                    pinSheetActionButton(title: "Cancel", action: { dismiss() })

                    if step == .confirmPIN {
                        pinSheetActionButton(title: "Back") {
                            confirmPIN = ""
                            pin = ""
                            step = .enterPIN
                            errorMessage = nil
                        }
                    }
                }
            }
            .padding(24)
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    /// Validates and stores the confirmed PIN plus backup phone number.
    private func savePIN() {
        guard pin == confirmPIN else {
            errorMessage = "PINs did not match. Try again."
            confirmPIN = ""
            pin = ""
            step = .enterPIN
            return
        }

        /*
        let normalizedPhone = backupPhone.filter(\.isNumber)
        guard normalizedPhone.count >= 10 else {
            errorMessage = "Add a backup phone number with at least 10 digits."
            confirmPIN = ""
            return
        }
        */

        ParentModeStore.setPIN(pin)
        // ParentModeStore.backupPhoneNumber = normalizedPhone
        ParentModeStore.needsParentPINUpdate = false
        dismiss()
    }

    /// Builds a secondary sheet action button with a full-width tap target.
    private func pinSheetActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                .foregroundStyle(ContinuumTheme.testMagenta)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .fullRoundedHitTarget(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
}

/// Sheet that verifies the backup phone number before setting a new parent PIN.
struct ParentPINResetSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var step: ResetStep = .enterPIN
    @State private var errorMessage: String?

    private enum ResetStep {
        // case verifyPhone
        case enterPIN
        case confirmPIN
    }

    var body: some View {
        ZStack {
            ContinuumTheme.homePink.ignoresSafeArea()

            VStack(spacing: 20) {
                switch step {
                /*
                case .verifyPhone:
                    VStack(spacing: 16) {
                        Text("Reset Parent PIN")
                            .font(ContinuumTheme.kidSectionHeaderFont)
                            .foregroundStyle(ContinuumTheme.testMagenta)

                        Text("Enter the backup phone number saved with your PIN.")
                            .font(ContinuumTheme.kidCaptionFont)
                            .foregroundStyle(ContinuumTheme.subtitleGray)
                            .multilineTextAlignment(.center)

                        TextField("Backup phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .font(ContinuumTheme.kidBodyFont)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if let errorMessage {
                            Text(errorMessage)
                                .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button("Continue") {
                            verifyPhone()
                        }
                        .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(ContinuumTheme.testMagenta)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .buttonStyle(.plain)
                    }
                */

                case .enterPIN:
                    ParentPINDigitEntryView(
                        pin: $newPIN,
                        title: "New Parent PIN",
                        subtitle: "Choose a new 4-digit PIN.",
                        errorMessage: errorMessage
                    )
                    .onChange(of: newPIN) { _, value in
                        guard value.count == 4 else { return }
                        errorMessage = nil
                        step = .confirmPIN
                    }

                case .confirmPIN:
                    ParentPINDigitEntryView(
                        pin: $confirmPIN,
                        title: "Confirm New PIN",
                        subtitle: "Enter the same PIN again.",
                        errorMessage: errorMessage
                    )
                    .onChange(of: confirmPIN) { _, value in
                        guard value.count == 4 else { return }
                        finishReset()
                    }
                }

                Button("Cancel") { dismiss() }
                    .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                    .foregroundStyle(ContinuumTheme.testMagenta)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .fullRoundedHitTarget(cornerRadius: 14)
                    .buttonStyle(.plain)
            }
            .padding(24)
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    /*
    /// Checks the backup phone number before allowing a new PIN.
    private func verifyPhone() {
        let entered = phoneNumber.filter(\.isNumber)
        let saved = (ParentModeStore.backupPhoneNumber ?? "").filter(\.isNumber)
        guard !entered.isEmpty, entered == saved else {
            errorMessage = "That phone number does not match the saved backup number."
            return
        }
        errorMessage = nil
        step = .enterPIN
    }
    */

    /// Saves the confirmed replacement PIN and closes the sheet.
    private func finishReset() {
        guard newPIN == confirmPIN else {
            errorMessage = "PINs did not match. Try again."
            confirmPIN = ""
            newPIN = ""
            step = .enterPIN
            return
        }

        ParentModeStore.setPIN(newPIN)
        dismiss()
    }
}

/// Full-screen prompt shown when leaving child mode and returning to the parent home.
struct ParentPINUnlockSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onUnlocked: () -> Void

    @State private var pin = ""
    @State private var errorMessage: String?
    // @State private var statusMessage: String?
    // @State private var usesTemporaryPIN = false
    // @State private var showSMSComposer = false
    // @State private var smsRecipients: [String] = []
    // @State private var smsBody = ""

    private var entryTitle: String {
        "Enter Parent PIN"
    }

    private var entrySubtitle: String {
        "Parents can enter their 4-digit PIN to switch back."
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ContinuumTheme.homePink, ContinuumTheme.homeOffWhite],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(BrocaBearCatalog.defaultPose)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .accessibilityHidden(true)

                ParentPINDigitEntryView(
                    pin: $pin,
                    title: entryTitle,
                    subtitle: entrySubtitle,
                    errorMessage: errorMessage
                )
                .frame(maxWidth: 420)

                /*
                if !usesTemporaryPIN {
                    Button(action: requestTemporaryPIN) {
                        Text("Forgot PIN?")
                            .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                            .foregroundStyle(ContinuumTheme.testMagenta)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .fullRoundedHitTarget(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        usesTemporaryPIN = false
                        pin = ""
                        errorMessage = nil
                        statusMessage = nil
                    } label: {
                        Text("Use parent PIN instead")
                            .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                            .foregroundStyle(ContinuumTheme.testMagenta)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .fullRoundedHitTarget(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                }
                */

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(ContinuumTheme.testMagenta)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .fullRoundedHitTarget(cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
        .onChange(of: pin) { _, newValue in
            guard newValue.count == 4 else { return }
            attemptUnlock()
        }
        /*
        .sheet(isPresented: $showSMSComposer) {
            ParentPINSMSComposer(
                recipients: smsRecipients,
                body: smsBody,
                onFinish: handleSMSComposeResult
            )
        }
        */
    }

    /*
    /// Generates a temporary PIN and opens the SMS recovery flow.
    private func requestTemporaryPIN() {
        guard let backupPhone = ParentModeStore.backupPhoneNumber, !backupPhone.isEmpty else {
            errorMessage = "No backup phone number is saved. Ask the parent to reset the PIN on their device."
            return
        }

        let temporaryPIN = ParentModeStore.issueTemporaryPIN()
        let message = ParentPINSMSDelivery.messageBody(for: temporaryPIN)
        errorMessage = nil
        pin = ""

        if ParentPINSMSDelivery.canSendText {
            smsRecipients = [backupPhone]
            smsBody = message
            showSMSComposer = true
        } else if ParentPINSMSDelivery.openPrefilledMessage(phoneNumber: backupPhone, body: message) {
            beginTemporaryPINEntry()
        } else {
            errorMessage = "Unable to send a text message from this device."
            ParentModeStore.clearTemporaryPIN()
        }
    }

    /// Switches the unlock screen to temporary PIN entry after the recovery text is sent.
    private func beginTemporaryPINEntry() {
        usesTemporaryPIN = true
        statusMessage = "Send the text if needed, then enter the 6-digit code sent to \(ParentModeStore.maskedBackupPhoneNumber() ?? "your backup phone")."
    }

    /// Continues into temporary PIN entry once the SMS composer finishes.
    private func handleSMSComposeResult(_ result: MessageComposeResult) {
        switch result {
        case .sent:
            beginTemporaryPINEntry()
        case .cancelled:
            ParentModeStore.clearTemporaryPIN()
            errorMessage = "Send the text message to receive your temporary PIN, then tap Forgot PIN again."
        case .failed:
            errorMessage = "The text message could not be sent. Try again."
            ParentModeStore.clearTemporaryPIN()
        @unknown default:
            errorMessage = "The text message could not be sent. Try again."
            ParentModeStore.clearTemporaryPIN()
        }
    }
    */

    /// Validates the entered PIN and unlocks parent mode when it matches.
    private func attemptUnlock() {
        if ParentModeStore.verifyPIN(pin) {
            ParentModeStore.clearTemporaryPIN()
            onUnlocked()
            dismiss()
        } else {
            errorMessage = "Incorrect PIN. Try again."
            pin = ""
        }
    }
}

/// Payload used to present the saved parent PIN sheet with fresh content each time.
struct ParentPINDisplayContent: Identifiable {
    let id = UUID()
    let pinText: String
    let isUnavailableMessage: Bool
}

/// Themed sheet that displays the saved parent PIN for reference.
struct ParentPINDisplaySheet: View {
    @Environment(\.dismiss) private var dismiss

    let pinText: String
    var isUnavailableMessage = false

    var body: some View {
        ZStack {
            ContinuumTheme.homePink.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Your Parent PIN")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .foregroundStyle(ContinuumTheme.testMagenta)
                    .frame(maxWidth: .infinity)

                Group {
                    if isUnavailableMessage {
                        Text(pinText)
                            .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                            .foregroundStyle(ContinuumTheme.pencilLead)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(pinText)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead)
                            .multilineTextAlignment(.center)
                            .tracking(6)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
                .layoutPriority(1)

                Button {
                    dismiss()
                } label: {
                    Text("OK")
                        .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(ContinuumTheme.testMagenta)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .fullRoundedHitTarget(cornerRadius: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(ContinuumTheme.tabPurple.opacity(0.5), lineWidth: 5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }
}
