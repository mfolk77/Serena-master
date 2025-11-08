// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

@main
struct SerenaNetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("SerenaNet MVP")
                .font(.largeTitle)
                .padding()
            
            Text("Local AI Assistant")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

#Preview {
    ContentView()
}
