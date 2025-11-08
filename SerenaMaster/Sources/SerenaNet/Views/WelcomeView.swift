import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var configManager: ConfigManager
    @State private var showOnboarding = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App icon or logo placeholder
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                Text("Welcome to SerenaNet")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Your local AI assistant")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "lock.shield",
                    title: "Private & Secure",
                    description: "All conversations stay on your device"
                )
                
                FeatureRow(
                    icon: "wifi.slash",
                    title: "Works Offline",
                    description: "No internet connection required"
                )
                
                FeatureRow(
                    icon: "mic",
                    title: "Voice Input",
                    description: "Speak naturally to interact"
                )
            }
            .padding(.top, 8)
            
            HStack(spacing: 12) {
                Button("Quick Start Guide") {
                    showOnboarding = true
                }
                .buttonStyle(.bordered)
                
                Button("Get Help") {
                    NSWorkspace.shared.open(URL(string: "https://serenatools.com/help")!)
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 16)
            
            Text("Start a conversation below to get started")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
        .frame(maxWidth: 500)
        .sheet(isPresented: $showOnboarding) {
            Text("Welcome to SerenaNet!")
                .padding()
                .frame(minWidth: 400, minHeight: 300)
        }
        .onAppear {
            // Show onboarding for first-time users
            if configManager.isFirstLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .frame(width: 600, height: 500)
}