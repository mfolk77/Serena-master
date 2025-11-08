import Foundation
import os.log

/// Parses tool calls from AI responses and extracts parameters
@MainActor
class ToolCallParser {
    static let shared = ToolCallParser()
    private let logger = Logger(subsystem: "com.serenanet.tools", category: "ToolCallParser")

    struct ToolCall {
        let tool: String
        let action: String?
        let params: [String: String]
        let rawLine: String

        var ftaiTask: String {
            var task = "task: \(tool)"
            if let action = action {
                task += ".\(action)"
            }
            task += "\n"

            for (key, value) in params {
                task += "\(key): \(value)\n"
            }

            return task
        }
    }

    private init() {}

    /// Parse tool calls from AI response
    /// Format: TOOL:calendar action:create_event title:Meeting date:tomorrow
    func parseToolCalls(from response: String) -> [ToolCall] {
        var toolCalls: [ToolCall] = []

        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            guard trimmedLine.hasPrefix("TOOL:") else { continue }

            // Remove "TOOL:" prefix
            let toolLine = String(trimmedLine.dropFirst(5))

            // Parse the tool line
            if let toolCall = parseToolLine(toolLine, rawLine: trimmedLine) {
                toolCalls.append(toolCall)
                logger.info("📞 Parsed tool call: \(toolCall.tool) action:\(toolCall.action ?? "none")")
            }
        }

        return toolCalls
    }

    private func parseToolLine(_ line: String, rawLine: String) -> ToolCall? {
        // Split by spaces to get parts
        let parts = line.components(separatedBy: " ")

        guard let toolName = parts.first else {
            logger.warning("Failed to parse tool name from: \(line)")
            return nil
        }

        var action: String?
        var params: [String: String] = [:]

        // Parse key:value pairs
        for part in parts.dropFirst() {
            let keyValue = part.components(separatedBy: ":")
            if keyValue.count >= 2 {
                let key = keyValue[0]
                let value = keyValue.dropFirst().joined(separator: ":") // Handle values with colons

                if key == "action" {
                    action = value
                } else {
                    params[key] = value
                }
            }
        }

        return ToolCall(
            tool: toolName,
            action: action,
            params: params,
            rawLine: rawLine
        )
    }

    /// Remove tool call lines from response to get clean text
    func removeToolCalls(from response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        let cleanedLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("TOOL:") }
        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
