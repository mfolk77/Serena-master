import SwiftUI
import LocalAuthentication

struct PasscodeView: View {
    @StateObject private var passcodeManager: PasscodeManager
    @State private var enteredPasscode: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isShaking: Bool = false
    
    let onUnlock: () -> Void
    
    init(passcodeManager: PasscodeManager, onUnlock: @escaping () -> Void) {
        self._passcodeManager = StateObject(wrappedValue: passcodeManager)
        self.onUnlock = onUnlock
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon/Logo
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text("SerenaNet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your passcode to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Passcode Input
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPasscode.count ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 15, height: 15)
                    }
                }
                .offset(x: isShaking ? -10 : 0)
                .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: isShaking)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Number Pad
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 20) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    // Biometric button (if available)
                    if passcodeManager.canUseBiometrics() {
                        BiometricButton {
                            Task {
                                await authenticateWithBiometrics()
                            }
                        }
                    } else {
                        Spacer()
                            .frame(width: 60, height: 60)
                    }
                    
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    
                    Button(action: removeDigit) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Auto-attempt biometric authentication if available
            if passcodeManager.canUseBiometrics() {
                Task {
                    await authenticateWithBiometrics()
                }
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPasscode.count < 6 else { return }
        
        enteredPasscode += digit
        
        // Auto-verify when 4+ digits are entered
        if enteredPasscode.count >= 4 {
            verifyPasscode()
        }
    }
    
    private func removeDigit() {
        if !enteredPasscode.isEmpty {
            enteredPasscode.removeLast()
        }
        clearError()
    }
    
    private func verifyPasscode() {
        do {
            let isValid = try passcodeManager.verifyPasscode(enteredPasscode)
            
            if isValid {
                onUnlock()
            } else {
                showInvalidPasscodeError()
            }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func authenticateWithBiometrics() async {
        do {
            let success = try await passcodeManager.authenticateWithBiometrics()
            if success {
                await MainActor.run {
                    onUnlock()
                }
            }
        } catch {
            await MainActor.run {
                // Silently fail biometric authentication - user can still use passcode
            }
        }
    }
    
    private func showInvalidPasscodeError() {
        enteredPasscode = ""
        showError("Invalid passcode. Please try again.")
        
        // Shake animation
        withAnimation {
            isShaking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShaking = false
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Clear error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            clearError()
        }
    }
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(width: 60, height: 60)
        .background(Color.gray.opacity(0.1))
        .clipShape(Circle())
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}

struct BiometricButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: biometricIcon)
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .frame(width: 60, height: 60)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Circle())
        .buttonStyle(PlainButtonStyle())
    }
    
    private var biometricIcon: String {
        let context = LAContext()
        
        switch context.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "person.crop.circle"
        }
    }
}

#Preview {
    PasscodeView(passcodeManager: PasscodeManager()) {
        print("Unlocked!")
    }
}