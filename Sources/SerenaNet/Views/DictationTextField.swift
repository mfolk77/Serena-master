import SwiftUI
import AppKit

/// A text field that supports macOS system dictation
struct DictationTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Message SerenaNet..."
    var isEnabled: Bool = true
    var onSubmit: () -> Void = {}

    @FocusState.Binding var isFocused: Bool

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.delegate = context.coordinator
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 6
        textField.usesSingleLineMode = false

        // Enable dictation
        textField.allowsEditingTextAttributes = true

        // Set the field editor to support dictation
        if let fieldEditor = textField.currentEditor() as? NSTextView {
            fieldEditor.isAutomaticTextCompletionEnabled = true
            fieldEditor.isAutomaticSpellingCorrectionEnabled = true
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.isEnabled = isEnabled
        nsView.placeholderString = placeholder

        // Handle focus state
        if isFocused && nsView.window?.firstResponder != nsView.currentEditor() {
            nsView.window?.makeFirstResponder(nsView)
        } else if !isFocused && nsView.window?.firstResponder == nsView.currentEditor() {
            nsView.window?.makeFirstResponder(nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: DictationTextField

        init(_ parent: DictationTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle return key for submission
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }

        // Enable dictation when field becomes first responder
        func controlTextDidBeginEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField,
                  let textView = textField.currentEditor() as? NSTextView else { return }

            // Enable all text input features including dictation
            textView.isAutomaticTextCompletionEnabled = true
            textView.isAutomaticSpellingCorrectionEnabled = true
            textView.isAutomaticQuoteSubstitutionEnabled = true
            textView.isAutomaticDashSubstitutionEnabled = true

            parent.isFocused = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            parent.isFocused = false
        }
    }
}
