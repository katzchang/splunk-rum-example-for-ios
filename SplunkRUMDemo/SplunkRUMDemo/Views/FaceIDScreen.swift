import SwiftUI
import LocalAuthentication

struct FaceIDScreen: View {
    @State private var authenticationStatus: AuthStatus = .notAuthenticated
    @State private var errorMessage: String?
    @State private var biometryType: LABiometryType = .none

    enum AuthStatus {
        case notAuthenticated
        case authenticating
        case authenticated
        case failed
    }

    var body: some View {
        VStack(spacing: 30) {
            // Status icon
            statusIcon
                .font(.system(size: 100))
                .padding(.top, 50)

            // Status text
            Text(statusText)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Authenticate button
            Button(action: authenticate) {
                HStack {
                    Image(systemName: biometryIconName)
                    Text(buttonText)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(authenticationStatus == .authenticated ? Color.green : Color.blue)
                .cornerRadius(12)
            }
            .disabled(authenticationStatus == .authenticating)
            .padding(.horizontal)

            // Reset button
            if authenticationStatus == .authenticated || authenticationStatus == .failed {
                Button(action: reset) {
                    Text("Reset")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Face ID")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometryType()
        }
    }

    private var statusIcon: some View {
        Group {
            switch authenticationStatus {
            case .notAuthenticated:
                Image(systemName: biometryIconName)
                    .foregroundColor(.blue)
            case .authenticating:
                ProgressView()
                    .scaleEffect(2)
            case .authenticated:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    private var statusText: String {
        switch authenticationStatus {
        case .notAuthenticated:
            return "Tap the button below to authenticate with \(biometryTypeName)"
        case .authenticating:
            return "Authenticating..."
        case .authenticated:
            return "Authentication Successful!"
        case .failed:
            return "Authentication Failed"
        }
    }

    private var buttonText: String {
        switch authenticationStatus {
        case .notAuthenticated, .failed:
            return "Authenticate with \(biometryTypeName)"
        case .authenticating:
            return "Authenticating..."
        case .authenticated:
            return "Authenticated"
        }
    }

    private var biometryIconName: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.shield"
        }
    }

    private var biometryTypeName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }

    private func checkBiometryType() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometryType = context.biometryType
        } else {
            biometryType = .none
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        authenticationStatus = .authenticating
        errorMessage = nil

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access secure content"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        authenticationStatus = .authenticated
                    } else {
                        authenticationStatus = .failed
                        if let error = authenticationError as? LAError {
                            switch error.code {
                            case .userCancel:
                                errorMessage = "Authentication was cancelled"
                            case .userFallback:
                                errorMessage = "User chose to use fallback"
                            case .biometryNotAvailable:
                                errorMessage = "Biometry is not available"
                            case .biometryNotEnrolled:
                                errorMessage = "Biometry is not enrolled"
                            case .biometryLockout:
                                errorMessage = "Biometry is locked out"
                            default:
                                errorMessage = "Authentication failed: \(error.localizedDescription)"
                            }
                        }
                    }
                }
            }
        } else {
            authenticationStatus = .failed
            errorMessage = "Biometric authentication is not available on this device"
        }
    }

    private func reset() {
        authenticationStatus = .notAuthenticated
        errorMessage = nil
    }
}

#Preview {
    NavigationStack {
        FaceIDScreen()
    }
}
