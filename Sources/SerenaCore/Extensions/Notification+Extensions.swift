import Foundation

extension Notification.Name {
    /// Notification sent when the message input should be focused
    static let focusMessageInput = Notification.Name("focusMessageInput")
    
    /// Notification sent when a new message is added
    static let messageAdded = Notification.Name("messageAdded")
    
    /// Notification sent when AI processing starts
    static let aiProcessingStarted = Notification.Name("aiProcessingStarted")
    
    /// Notification sent when AI processing completes
    static let aiProcessingCompleted = Notification.Name("aiProcessingCompleted")
    
    /// Notification sent when conversation is changed
    static let conversationChanged = Notification.Name("conversationChanged")
}
