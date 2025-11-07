    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let actionIdentifier = response.actionIdentifier
            
            switch actionIdentifier {
            case "VIEW_RESPONSE", "VIEW_TRANSCRIPTION":
                // Bring app to foreground and focus on chat
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                
            default:
                // Default action (tap on notification)
                NSApp.activate(ignoringOtherApps: true)
            }
            
            completionHandler()
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
