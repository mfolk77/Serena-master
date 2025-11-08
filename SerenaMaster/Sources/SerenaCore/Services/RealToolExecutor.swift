import Foundation
import EventKit
import AppKit
import os.log

/// Real tool executor with actual macOS API implementations
/// Replaces stub implementations with EventKit, FileManager, and NSWorkspace
@MainActor
class RealToolExecutor {
    static let shared = RealToolExecutor()
    private let logger = Logger(subsystem: "com.serenanet.tools", category: "RealToolExecutor")

    // EventKit for calendar operations
    private let eventStore = EKEventStore()
    private var calendarAccessGranted = false

    private init() {
        Task {
            await requestCalendarAccess()
        }
    }

    struct ToolResult {
        let success: Bool
        let output: String
        let error: String?
    }

    // MARK: - Calendar Access

    private func requestCalendarAccess() async {
        do {
            calendarAccessGranted = try await eventStore.requestAccess(to: .event)
            if calendarAccessGranted {
                logger.info("✅ Calendar access granted")
            } else {
                logger.warning("⚠️ Calendar access denied")
            }
        } catch {
            logger.error("❌ Calendar access request failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Execute Tool

    func execute(_ ftaiTask: String) async throws -> ToolResult {
        logger.info("📞 Executing real tool task:\n\(ftaiTask)")

        // Parse FTAI task format
        let lines = ftaiTask.components(separatedBy: .newlines)
        guard let taskLine = lines.first else {
            throw ToolExecutorError.invalidTask("Empty task")
        }

        // Extract tool and action
        let taskParts = taskLine.replacingOccurrences(of: "task: ", with: "").components(separatedBy: ".")
        guard let toolName = taskParts.first else {
            throw ToolExecutorError.invalidTask("No tool name")
        }

        let action = taskParts.count > 1 ? taskParts[1] : nil

        // Extract parameters
        var params: [String: String] = [:]
        for line in lines.dropFirst() {
            let parts = line.components(separatedBy: ": ")
            if parts.count >= 2 {
                let key = parts[0]
                let value = parts.dropFirst().joined(separator: ": ")
                params[key] = value
            }
        }

        logger.info("🔧 Tool: \(toolName), Action: \(action ?? "none"), Params: \(params.count)")

        // Route to appropriate handler
        switch toolName.lowercased() {
        case "calendar":
            return await handleCalendarTool(action: action, params: params)
        case "file":
            return await handleFileTool(action: action, params: params)
        case "app":
            return await handleAppTool(action: action, params: params)
        case "executive":
            return await handleExecutiveTool(action: action, params: params)
        default:
            throw ToolExecutorError.unknownTool(toolName)
        }
    }

    // MARK: - Calendar Tool (Real EventKit)

    private func handleCalendarTool(action: String?, params: [String: String]) async -> ToolResult {
        logger.info("📅 Calendar tool (REAL EventKit): \(action ?? "unknown")")

        guard calendarAccessGranted else {
            return ToolResult(
                success: false,
                output: "",
                error: "Calendar access not granted. Please allow calendar access in System Settings."
            )
        }

        switch action {
        case "create_event":
            let title = params["title"] ?? "Untitled Event"
            let dateStr = params["date"] ?? "today"
            let timeStr = params["time"] ?? "now"

            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.calendar = eventStore.defaultCalendarForNewEvents

            // Parse date and time
            let startDate = parseDateTime(date: dateStr, time: timeStr)
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(3600) // 1 hour duration

            do {
                try eventStore.save(event, span: .thisEvent)
                logger.info("✅ Created calendar event: \(title)")
                return ToolResult(
                    success: true,
                    output: "Created calendar event '\(title)' on \(formatDate(startDate))",
                    error: nil
                )
            } catch {
                logger.error("❌ Failed to create event: \(error.localizedDescription)")
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to create calendar event: \(error.localizedDescription)"
                )
            }

        case "create_reminder":
            let title = params["title"] ?? "Untitled Reminder"
            let dateStr = params["date"] ?? "today"

            // Use reminders
            do {
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = title
                reminder.calendar = eventStore.defaultCalendarForNewReminders()

                let dueDate = parseDateTime(date: dateStr, time: "09:00")
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

                try eventStore.save(reminder, commit: true)
                logger.info("✅ Created reminder: \(title)")
                return ToolResult(
                    success: true,
                    output: "Created reminder '\(title)' for \(formatDate(dueDate))",
                    error: nil
                )
            } catch {
                logger.error("❌ Failed to create reminder: \(error.localizedDescription)")
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to create reminder: \(error.localizedDescription)"
                )
            }

        case "search_events":
            let query = params["query"] ?? ""
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!

            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let events = eventStore.events(matching: predicate)
                .filter { $0.title.localizedCaseInsensitiveContains(query) }

            let results = events.prefix(5).map { "• \($0.title) - \(formatDate($0.startDate))" }.joined(separator: "\n")

            return ToolResult(
                success: true,
                output: "Found \(events.count) event(s) matching '\(query)':\n\(results)",
                error: nil
            )

        case "list_upcoming":
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)!

            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let events = eventStore.events(matching: predicate).prefix(10)

            let results = events.map { "• \($0.title) - \(formatDate($0.startDate))" }.joined(separator: "\n")

            return ToolResult(
                success: true,
                output: "Upcoming events this week:\n\(results)",
                error: nil
            )

        default:
            return ToolResult(
                success: false,
                output: "",
                error: "Unknown calendar action: \(action ?? "none")"
            )
        }
    }

    // MARK: - File Tool (Real FileManager)

    private func handleFileTool(action: String?, params: [String: String]) async -> ToolResult {
        logger.info("📁 File tool (REAL FileManager): \(action ?? "unknown")")

        let fileManager = FileManager.default

        switch action {
        case "search":
            let directory = NSString(string: params["directory"] ?? "~/Documents").expandingTildeInPath
            let query = params["query"] ?? ""
            let recursive = params["recursive"] == "true"

            var matches: [String] = []

            if recursive {
                // Recursive search
                if let enumerator = fileManager.enumerator(atPath: directory) {
                    for case let file as String in enumerator {
                        if file.localizedCaseInsensitiveContains(query) {
                            matches.append(file)
                            if matches.count >= 20 { break }
                        }
                    }
                }
            } else {
                // Non-recursive search
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: directory)
                    matches = contents.filter { $0.localizedCaseInsensitiveContains(query) }
                } catch {
                    return ToolResult(
                        success: false,
                        output: "",
                        error: "Failed to search directory: \(error.localizedDescription)"
                    )
                }
            }

            let results = matches.prefix(10).map { "• \($0)" }.joined(separator: "\n")
            return ToolResult(
                success: true,
                output: "Found \(matches.count) file(s) matching '\(query)' in \(directory):\n\(results)",
                error: nil
            )

        case "read":
            let path = NSString(string: params["path"] ?? "").expandingTildeInPath

            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                let preview = content.prefix(500)
                return ToolResult(
                    success: true,
                    output: "File content (\(content.count) chars):\n\(preview)\(content.count > 500 ? "..." : "")",
                    error: nil
                )
            } catch {
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to read file: \(error.localizedDescription)"
                )
            }

        case "list":
            let directory = NSString(string: params["directory"] ?? "~/Documents").expandingTildeInPath

            do {
                let contents = try fileManager.contentsOfDirectory(atPath: directory)
                let results = contents.prefix(20).map { "• \($0)" }.joined(separator: "\n")
                return ToolResult(
                    success: true,
                    output: "Files in \(directory) (\(contents.count) total):\n\(results)",
                    error: nil
                )
            } catch {
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to list directory: \(error.localizedDescription)"
                )
            }

        case "create":
            let path = NSString(string: params["path"] ?? "").expandingTildeInPath
            let content = params["content"] ?? ""

            do {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                return ToolResult(
                    success: true,
                    output: "Created file at \(path)",
                    error: nil
                )
            } catch {
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to create file: \(error.localizedDescription)"
                )
            }

        case "delete":
            let path = NSString(string: params["path"] ?? "").expandingTildeInPath

            do {
                try fileManager.removeItem(atPath: path)
                return ToolResult(
                    success: true,
                    output: "Deleted file at \(path)",
                    error: nil
                )
            } catch {
                return ToolResult(
                    success: false,
                    output: "",
                    error: "Failed to delete file: \(error.localizedDescription)"
                )
            }

        default:
            return ToolResult(
                success: false,
                output: "",
                error: "Unknown file action: \(action ?? "none")"
            )
        }
    }

    // MARK: - App Tool (Real NSWorkspace)

    private func handleAppTool(action: String?, params: [String: String]) async -> ToolResult {
        logger.info("🚀 App tool (REAL NSWorkspace): \(action ?? "unknown")")

        let workspace = NSWorkspace.shared

        switch action {
        case "launch":
            let appName = params["app_name"] ?? ""

            // Try different methods to find and launch the app
            let possibleBundleIds = [
                "com.apple.\(appName.lowercased())",
                "com.\(appName.lowercased()).\(appName.lowercased())"
            ]

            // Try by bundle ID
            for bundleId in possibleBundleIds {
                if let url = workspace.urlForApplication(withBundleIdentifier: bundleId) {
                    do {
                        try workspace.launchApplication(at: url, options: [], configuration: [:])
                        logger.info("✅ Launched app: \(appName)")
                        return ToolResult(
                            success: true,
                            output: "Launched \(appName)",
                            error: nil
                        )
                    } catch {
                        continue
                    }
                }
            }

            // Try by application name
            let appPaths = [
                "/Applications/\(appName).app",
                "/System/Applications/\(appName).app",
                "/Applications/Utilities/\(appName).app"
            ]

            for path in appPaths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path) {
                    do {
                        try workspace.launchApplication(at: url, options: [], configuration: [:])
                        logger.info("✅ Launched app: \(appName)")
                        return ToolResult(
                            success: true,
                            output: "Launched \(appName)",
                            error: nil
                        )
                    } catch {
                        continue
                    }
                }
            }

            return ToolResult(
                success: false,
                output: "",
                error: "Could not find or launch app '\(appName)'"
            )

        case "quit":
            let appName = params["app_name"] ?? ""

            let runningApps = workspace.runningApplications
            for app in runningApps {
                if app.localizedName?.lowercased() == appName.lowercased() {
                    app.terminate()
                    logger.info("✅ Quit app: \(appName)")
                    return ToolResult(
                        success: true,
                        output: "Quit \(appName)",
                        error: nil
                    )
                }
            }

            return ToolResult(
                success: false,
                output: "",
                error: "App '\(appName)' is not running"
            )

        case "list_active":
            let apps = workspace.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap { $0.localizedName }
                .prefix(15)
                .map { "• \($0)" }
                .joined(separator: "\n")

            return ToolResult(
                success: true,
                output: "Active applications:\n\(apps)",
                error: nil
            )

        default:
            return ToolResult(
                success: false,
                output: "",
                error: "Unknown app action: \(action ?? "none")"
            )
        }
    }

    // MARK: - Executive Tool (Stub - for future expansion)

    private func handleExecutiveTool(action: String?, params: [String: String]) async -> ToolResult {
        logger.info("💼 Executive tool: \(action ?? "unknown")")

        let role = params["role"] ?? "unknown"
        let operation = params["operation"] ?? "unknown"

        // This would connect to actual business logic systems
        return ToolResult(
            success: true,
            output: "Executive \(role) operation '\(operation)' acknowledged (requires business logic implementation)",
            error: nil
        )
    }

    // MARK: - Helper Methods

    private func parseDateTime(date: String, time: String) -> Date {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        // Parse date
        let dateLower = date.lowercased()
        if dateLower == "today" {
            // Use current date
        } else if dateLower == "tomorrow" {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            }
        }

        // Parse time
        let timeParts = time.components(separatedBy: ":")
        if timeParts.count >= 2 {
            dateComponents.hour = Int(timeParts[0])
            dateComponents.minute = Int(timeParts[1])
        } else {
            // Try parsing formats like "2pm"
            let timeStr = time.lowercased().replacingOccurrences(of: " ", with: "")
            if let hour = Int(timeStr.replacingOccurrences(of: "pm", with: "").replacingOccurrences(of: "am", with: "")) {
                dateComponents.hour = timeStr.contains("pm") && hour != 12 ? hour + 12 : hour
                dateComponents.minute = 0
            } else {
                // Default to current hour
                dateComponents.hour = calendar.component(.hour, from: Date())
                dateComponents.minute = 0
            }
        }

        return calendar.date(from: dateComponents) ?? Date()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}