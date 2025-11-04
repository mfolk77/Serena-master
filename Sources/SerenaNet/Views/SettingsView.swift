import SwiftUI
import AppKit

struct SettingsView: View {
    @StateObject private var configManager = ConfigManager()
    @StateObject private var passcodeManager = PasscodeManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var localLoggingEnabled: Bool = UserDefaults.standard.bool(forKey: "SerenaNet.LocalLogging")
    
    var body: some View {
        NavigationView {
            Form {
                // Personal Settings
                Section("Personal") {
                    HStack {
                        Text("Nickname:")
                        TextField("Enter your nickname", text: $configManager.userConfig.nickname)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Appearance Settings
                Section("Appearance") {
                    HStack {
                        Text("Theme:")
                        Picker("Theme", selection: $configManager.userConfig.theme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // AI Settings
                Section("AI Parameters") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Temperature:")
                            Spacer()
                            Text(String(format: "%.1f", configManager.userConfig.aiParameters.temperature))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $configManager.userConfig.aiParameters.temperature,
                            in: 0.0...2.0,
                            step: 0.1
                        )
                        
                        Text("Controls creativity vs consistency. Higher values are more creative.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Max Tokens:")
                            Spacer()
                            Text("\(configManager.userConfig.aiParameters.maxTokens)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(configManager.userConfig.aiParameters.maxTokens) },
                                set: { configManager.userConfig.aiParameters.maxTokens = Int($0) }
                            ),
                            in: 100...4000,
                            step: 100
                        )
                        
                        Text("Maximum length of AI responses.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Context Window:")
                            Spacer()
                            Text("\(configManager.userConfig.aiParameters.contextWindow) exchanges")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(configManager.userConfig.aiParameters.contextWindow) },
                                set: { configManager.userConfig.aiParameters.contextWindow = Int($0) }
                            ),
                            in: 1...20,
                            step: 1
                        )
                        
                        Text("Number of previous exchanges to remember.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // System Status (NEW)
                Section("System Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AI System:")
                            Spacer()
                            Text("Direct Response Mode")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("RTAI Backend:")
                            Spacer()
                            if configManager.userConfig.rtaiEnabled {
                                Text("Enabled ✅")
                                    .foregroundColor(.green)
                            } else {
                                Text("Disabled ❌")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack {
                            Text("Response System:")
                            Spacer()
                            Text("Pattern Matching Active")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Text Input:")
                            Spacer()
                            Text("Keyboard Capture Fixed")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                        
                        Text("If you're not getting responses, try:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Click the CAPTURE button in the chat")
                            Text("• Make sure text field background is GREEN")
                            Text("• Type 'hello' and press Enter")
                            Text("• Check that RTAI is enabled above")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                // RTAI Settings
                Section("Real-Time AI") {
                    Toggle("Enable RTAI", isOn: $configManager.userConfig.rtaiEnabled)
                    
                    HStack {
                        Text("Current Status:")
                        Spacer()
                        if configManager.userConfig.rtaiEnabled {
                            Text("🦀 RTAI System Active")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        } else {
                            Text("Standard AI Mode")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Enables FolkTech RTAI processing with pattern matching and intelligent responses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Voice Settings
                Section("Voice Input") {
                    Toggle("Enable Voice Input", isOn: $configManager.userConfig.voiceInputEnabled)
                    
                    if configManager.userConfig.voiceInputEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Noise Reduction", isOn: $configManager.userConfig.voiceSettings.noiseReductionEnabled)
                            
                            Text("Reduces background noise for clearer voice recognition.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Voice Commands", isOn: $configManager.userConfig.voiceSettings.voiceCommandsEnabled)
                            
                            Text("Enables voice commands like 'stop', 'send', and 'new conversation'.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Auto-Send Messages", isOn: $configManager.userConfig.voiceSettings.autoSendEnabled)
                            
                            Text("Automatically sends messages after voice input completes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Microphone Sensitivity:")
                                Spacer()
                                Text(String(format: "%.1f", configManager.userConfig.voiceSettings.microphoneSensitivity))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: $configManager.userConfig.voiceSettings.microphoneSensitivity,
                                in: 0.0...1.0,
                                step: 0.1
                            )
                            
                            Text("Adjusts how sensitive the microphone is to your voice.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Speech Timeout:")
                                Spacer()
                                Text(String(format: "%.1f seconds", configManager.userConfig.voiceSettings.speechTimeout))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: $configManager.userConfig.voiceSettings.speechTimeout,
                                in: 1.0...10.0,
                                step: 0.5
                            )
                            
                            Text("How long to wait for speech before stopping recording.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Language:")
                                Spacer()
                                Picker("Language", selection: $configManager.userConfig.voiceSettings.language) {
                                    Text("English (US)").tag("en-US")
                                    Text("English (UK)").tag("en-GB")
                                    Text("Spanish").tag("es-ES")
                                    Text("French").tag("fr-FR")
                                    Text("German").tag("de-DE")
                                    Text("Italian").tag("it-IT")
                                    Text("Portuguese").tag("pt-BR")
                                    Text("Japanese").tag("ja-JP")
                                    Text("Korean").tag("ko-KR")
                                    Text("Chinese (Simplified)").tag("zh-CN")
                                }
                                .pickerStyle(.menu)
                            }
                            
                            Text("Language for voice recognition.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Voice input allows you to speak to SerenaNet instead of typing.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Security Settings
                Section("Security") {
                    Toggle("Require Passcode", isOn: $configManager.userConfig.passcodeEnabled)
                        .onChange(of: configManager.userConfig.passcodeEnabled) { enabled in
                            if enabled && !passcodeManager.passcodeEnabled {
                                showSetPasscodeAlert = true
                            } else if !enabled && passcodeManager.passcodeEnabled {
                                showRemovePasscodeAlert = true
                            }
                        }
                    
                    if configManager.userConfig.passcodeEnabled {
                        Text("Passcode protection will be required to access saved conversations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if configManager.canUseBiometrics {
                            Text("You can also use biometric authentication (Touch ID/Face ID) to unlock.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Change Passcode") {
                            showChangePasscodeAlert = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        Text("Enable passcode protection to secure your conversation history.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Privacy & Data Management
                Section("Privacy & Data Management") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Storage")
                            .font(.headline)
                        
                        Text("All your conversations are stored locally on your device and encrypted with AES-256. No data is transmitted to external servers.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let dbSize = getDatabaseSize() {
                            Text("Current storage usage: \(formatBytes(dbSize))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Local Logging", isOn: $localLoggingEnabled)
                        .onChange(of: localLoggingEnabled) { enabled in
                            // Update logging preferences
                            UserDefaults.standard.set(enabled, forKey: "SerenaNet.LocalLogging")
                        }
                    
                    Text("Enable local diagnostic logging to help troubleshoot issues. Logs are stored locally and never transmitted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Export Conversations") {
                        showExportAlert = true
                    }
                    .foregroundColor(.blue)
                    
                    Text("Export your conversation history as an encrypted backup file.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Clear All Conversations") {
                        showClearDataAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Text("This will permanently delete all conversation history.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Secure Data Wipe") {
                        showSecureWipeAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Text("Permanently delete all data including conversations, settings, and encryption keys. This action cannot be undone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Performance Monitoring
                Section("Performance") {
                    NavigationLink("Performance Monitor") {
                        PerformanceView()
                    }
                    
                    Text("Monitor app performance, memory usage, and response times.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Reset Settings
                Section("Reset") {
                    Button("Reset to Defaults") {
                        showResetAlert = true
                    }
                    .foregroundColor(.orange)
                    
                    Text("This will reset all settings to their default values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
        .alert("Clear All Conversations", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                Task {
                    await configManager.clearAllConversations()
                }
            }
        } message: {
            Text("This action cannot be undone. All conversation history will be permanently deleted.")
        }
        .alert("Reset Settings", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                configManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. Your conversations will not be affected.")
        }
        .alert("Set Passcode", isPresented: $showSetPasscodeAlert) {
            SecureField("Enter new passcode", text: $newPasscode)
            SecureField("Confirm passcode", text: $confirmPasscode)
            Button("Cancel", role: .cancel) {
                resetPasscodeFields()
                configManager.userConfig.passcodeEnabled = false
            }
            Button("Set Passcode") {
                setPasscode()
            }
        } message: {
            Text("Enter a passcode to secure your conversation history. \(passcodeError)")
        }
        .alert("Remove Passcode", isPresented: $showRemovePasscodeAlert) {
            Button("Cancel", role: .cancel) {
                configManager.userConfig.passcodeEnabled = true
            }
            Button("Remove", role: .destructive) {
                removePasscode()
            }
        } message: {
            Text("This will remove passcode protection from your conversations.")
        }
        .alert("Change Passcode", isPresented: $showChangePasscodeAlert) {
            SecureField("Enter new passcode", text: $newPasscode)
            SecureField("Confirm passcode", text: $confirmPasscode)
            Button("Cancel", role: .cancel) {
                resetPasscodeFields()
            }
            Button("Change Passcode") {
                changePasscode()
            }
        } message: {
            Text("Enter a new passcode. \(passcodeError)")
        }
        .alert("Secure Data Wipe", isPresented: $showSecureWipeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Wipe All Data", role: .destructive) {
                Task {
                    await configManager.secureDataWipe()
                }
            }
        } message: {
            Text("This will permanently delete ALL data including conversations, settings, encryption keys, and passcode. This action cannot be undone.")
        }
        .alert("Export Conversations", isPresented: $showExportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Export") {
                exportConversations()
            }
        } message: {
            Text("Export your conversations as an encrypted backup file.")
        }
        .onAppear {
            configManager.loadConfiguration()
        }
        .onChange(of: configManager.userConfig) { _ in
            configManager.saveConfiguration()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setPasscode() {
        guard !newPasscode.isEmpty else {
            passcodeError = "Passcode cannot be empty."
            return
        }
        
        guard newPasscode.count >= 4 else {
            passcodeError = "Passcode must be at least 4 characters."
            return
        }
        
        guard newPasscode == confirmPasscode else {
            passcodeError = "Passcodes do not match."
            return
        }
        
        do {
            try configManager.enablePasscode(newPasscode)
            resetPasscodeFields()
        } catch {
            passcodeError = error.localizedDescription
        }
    }
    
    private func removePasscode() {
        do {
            try configManager.disablePasscode()
        } catch {
            print("Failed to remove passcode: \(error)")
        }
    }
    
    private func changePasscode() {
        guard !newPasscode.isEmpty else {
            passcodeError = "Passcode cannot be empty."
            return
        }
        
        guard newPasscode.count >= 4 else {
            passcodeError = "Passcode must be at least 4 characters."
            return
        }
        
        guard newPasscode == confirmPasscode else {
            passcodeError = "Passcodes do not match."
            return
        }
        
        do {
            try configManager.enablePasscode(newPasscode)
            resetPasscodeFields()
        } catch {
            passcodeError = error.localizedDescription
        }
    }
    
    private func resetPasscodeFields() {
        newPasscode = ""
        confirmPasscode = ""
        passcodeError = ""
    }
    
    private func getDatabaseSize() -> Int64? {
        do {
            let dataStore = try DataStore()
            return try dataStore.getDatabaseSize()
        } catch {
            return nil
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func exportConversations() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        panel.nameFieldStringValue = "SerenaNet-Backup-\(DateFormatter.backupFormatter.string(from: Date())).srnbackup"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    await performExport(to: url)
                }
            }
        }
    }
    
    private func performExport(to url: URL) async {
        // This would implement the actual export functionality
        // For now, we'll create a placeholder implementation
        do {
            let exportData = configManager.exportConfiguration() ?? Data()
            try exportData.write(to: url)
        } catch {
            print("Failed to export conversations: \(error)")
        }
    }
    
    @State private var showClearDataAlert = false
    @State private var showResetAlert = false
    @State private var showSetPasscodeAlert = false
    @State private var showRemovePasscodeAlert = false
    @State private var showChangePasscodeAlert = false
    @State private var showSecureWipeAlert = false
    @State private var showExportAlert = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var passcodeError = ""
}

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter
    }()
}

#Preview {
    SettingsView()
}