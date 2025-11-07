import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var configManager: ConfigManager
    @State private var currentPage = 0
    @State private var nickname = ""
    @State private var enableVoiceInput = true
    @State private var enablePasscode = false
    
    private let pages = OnboardingPage.allCases
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Page-specific content
            switch page {
            case .welcome:
                EmptyView()
                
            case .privacy:
                VStack(spacing: 12) {
                    PrivacyFeature(icon: "lock.shield", text: "All data encrypted locally")
                    PrivacyFeature(icon: "wifi.slash", text: "No internet required")
                    PrivacyFeature(icon: "eye.slash", text: "No tracking or analytics")
                }
                
            case .personalization:
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should I call you?")
                            .font(.headline)
                        
                        TextField("Enter your name or nickname", text: $nickname)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.headline)
                        
                        Toggle("Enable voice input", isOn: $enableVoiceInput)
                        Toggle("Enable passcode protection", isOn: $enablePasscode)
                    }
                    .frame(maxWidth: 300)
                }
                
            case .voiceSetup:
                VStack(spacing: 16) {
                    Text("Voice input allows hands-free interaction with your AI assistant.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                    
                    if enableVoiceInput {
                        Button("Grant Microphone Permission") {
                            requestMicrophonePermission()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Voice input is disabled. You can enable it later in settings.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
            case .ready:
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 40))
                    
                    Text("You're all set! Start by typing a message or asking a question.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var canProceed: Bool {
        switch pages[currentPage] {
        case .personalization:
            return !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }
    
    private func requestMicrophonePermission() {
        // This would typically request microphone permission
        // For now, we'll just simulate it
        print("Requesting microphone permission...")
    }
    
    private func completeOnboarding() {
        // Save user preferences
        configManager.userConfig.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        configManager.userConfig.voiceInputEnabled = enableVoiceInput
        configManager.userConfig.passcodeEnabled = enablePasscode
        
        // Mark onboarding as complete
        configManager.completeOnboarding()
        
        dismiss()
    }
}

struct PrivacyFeature: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.callout)
            
            Spacer()
        }
        .frame(maxWidth: 300)
    }
}

enum OnboardingPage: CaseIterable {
    case welcome
    case privacy
    case personalization
    case voiceSetup
    case ready
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to SerenaNet"
        case .privacy:
            return "Your Privacy Matters"
        case .personalization:
            return "Let's Personalize"
        case .voiceSetup:
            return "Voice Input Setup"
        case .ready:
            return "Ready to Go!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "SerenaNet is your private AI assistant that runs entirely on your device. Let's get you set up!"
        case .privacy:
            return "Your conversations and data never leave your device. Everything is processed locally and encrypted for your security."
        case .personalization:
            return "Help us customize your experience by setting up your preferences."
        case .voiceSetup:
            return "Enable voice input to interact with your AI assistant hands-free using natural speech."
        case .ready:
            return "SerenaNet is configured and ready to assist you. Your private AI companion awaits!"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "brain.head.profile"
        case .privacy:
            return "lock.shield"
        case .personalization:
            return "person.crop.circle"
        case .voiceSetup:
            return "mic"
        case .ready:
            return "checkmark.circle"
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ConfigManager())
}