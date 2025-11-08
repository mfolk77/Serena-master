import Foundation

/// Parser for FTAI (Functional Task AI) documents
class FTAIParser {
    
    // MARK: - Error Types
    
    enum FTAIParseError: LocalizedError {
        case invalidFormat(String)
        case missingVersion
        case missingContent
        case invalidSchema(String)
        case unsupportedVersion(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat(let details):
                return "Invalid FTAI format: \(details)"
            case .missingVersion:
                return "FTAI document missing version information"
            case .missingContent:
                return "FTAI document missing content section"
            case .invalidSchema(let details):
                return "Invalid FTAI schema: \(details)"
            case .unsupportedVersion(let version):
                return "Unsupported FTAI version: \(version)"
            }
        }
    }
    
    // MARK: - Constants
    
    private static let supportedVersions = ["1.0", "1.1"]
    private static let versionPattern = #"^version:\s*(.+)$"#
    private static let metadataPattern = #"^(\w+):\s*(.+)$"#
    private static let schemaStartPattern = #"^schema:\s*$"#
    private static let contentStartPattern = #"^content:\s*$"#
    
    // MARK: - Public Methods
    
    /// Parse FTAI content from a string
    /// - Parameter content: The raw FTAI content to parse
    /// - Returns: A parsed FTAIDocument
    /// - Throws: FTAIParseError if parsing fails
    func parse(_ content: String) throws -> FTAIDocument {
        let lines = content.components(separatedBy: .newlines)
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FTAIParseError.invalidFormat("Empty content")
        }
        
        var version: String?
        var metadata: [String: String] = [:]
        var schema: FTAISchema?
        var documentContent: String = ""
        
        var currentSection: ParseSection = .header
        var schemaLines: [String] = []
        var contentLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            switch currentSection {
            case .header:
                // Skip empty lines and comments in header
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                if let parsedVersion = try parseVersion(from: trimmedLine) {
                    version = parsedVersion
                } else if isSchemaStart(trimmedLine) {
                    currentSection = .schema
                } else if isContentStart(trimmedLine) {
                    currentSection = .content
                } else if let (key, value) = parseMetadata(from: trimmedLine) {
                    metadata[key] = value
                }
                
            case .schema:
                // Skip empty lines and comments in schema
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                if isContentStart(trimmedLine) {
                    currentSection = .content
                } else {
                    schemaLines.append(trimmedLine)
                }
                
            case .content:
                // Preserve all lines in content, including comments and empty lines
                contentLines.append(line)
            }
        }
        
        // Validate required fields
        guard let documentVersion = version else {
            throw FTAIParseError.missingVersion
        }
        
        guard Self.supportedVersions.contains(documentVersion) else {
            throw FTAIParseError.unsupportedVersion(documentVersion)
        }
        
        // Parse schema if present
        if !schemaLines.isEmpty {
            schema = try parseSchema(from: schemaLines)
        }
        
        // Join content lines
        documentContent = contentLines.joined(separator: "\n")
        
        return FTAIDocument(
            version: documentVersion,
            metadata: metadata,
            content: documentContent,
            schema: schema
        )
    }
    
    /// Validate an FTAI document
    /// - Parameter document: The document to validate
    /// - Returns: True if valid, throws error if invalid
    /// - Throws: FTAIParseError if validation fails
    func validate(_ document: FTAIDocument) throws -> Bool {
        // Check version support
        guard Self.supportedVersions.contains(document.version) else {
            throw FTAIParseError.unsupportedVersion(document.version)
        }
        
        // Validate schema if present
        if let schema = document.schema {
            try validateSchema(schema)
        }
        
        // Content should not be empty for most use cases
        if document.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FTAIParseError.missingContent
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private enum ParseSection {
        case header
        case schema
        case content
    }
    
    private func parseVersion(from line: String) throws -> String? {
        let regex = try NSRegularExpression(pattern: Self.versionPattern, options: [])
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            let versionRange = Range(match.range(at: 1), in: line)!
            return String(line[versionRange]).trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
    
    private func parseMetadata(from line: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: Self.metadataPattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            let keyRange = Range(match.range(at: 1), in: line)!
            let valueRange = Range(match.range(at: 2), in: line)!
            
            let key = String(line[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = String(line[valueRange]).trimmingCharacters(in: .whitespaces)
            
            return (key, value)
        }
        
        return nil
    }
    
    private func isSchemaStart(_ line: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: Self.schemaStartPattern, options: []) else {
            return false
        }
        
        let range = NSRange(location: 0, length: line.utf16.count)
        return regex.firstMatch(in: line, options: [], range: range) != nil
    }
    
    private func isContentStart(_ line: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: Self.contentStartPattern, options: []) else {
            return false
        }
        
        let range = NSRange(location: 0, length: line.utf16.count)
        return regex.firstMatch(in: line, options: [], range: range) != nil
    }
    
    private func parseSchema(from lines: [String]) throws -> FTAISchema {
        var name: String?
        var version: String?
        var description: String?
        var fields: [FTAIField] = []
        
        for line in lines {
            if line.hasPrefix("name:") {
                name = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("version:") {
                version = String(line.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("description:") {
                description = String(line.dropFirst(12)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("field:") {
                if let field = try parseField(from: String(line.dropFirst(6))) {
                    fields.append(field)
                }
            }
        }
        
        guard let schemaName = name else {
            throw FTAIParseError.invalidSchema("Missing schema name")
        }
        
        guard let schemaVersion = version else {
            throw FTAIParseError.invalidSchema("Missing schema version")
        }
        
        return FTAISchema(
            name: schemaName,
            version: schemaVersion,
            fields: fields,
            description: description
        )
    }
    
    private func parseField(from fieldDefinition: String) throws -> FTAIField? {
        // Expected format: "name:type:required:description"
        let components = fieldDefinition.components(separatedBy: ":")
        guard components.count >= 2 else {
            return nil
        }
        
        let name = components[0].trimmingCharacters(in: .whitespaces)
        let typeString = components[1].trimmingCharacters(in: .whitespaces)
        
        guard let fieldType = FTAIFieldType(rawValue: typeString) else {
            throw FTAIParseError.invalidSchema("Unknown field type: \(typeString)")
        }
        
        let required = components.count > 2 ? components[2].trimmingCharacters(in: .whitespaces).lowercased() == "true" : false
        let description = components.count > 3 ? components[3].trimmingCharacters(in: .whitespaces) : nil
        
        return FTAIField(
            name: name,
            type: fieldType,
            required: required,
            description: description
        )
    }
    
    private func validateSchema(_ schema: FTAISchema) throws {
        // Validate schema name is not empty
        guard !schema.name.isEmpty else {
            throw FTAIParseError.invalidSchema("Schema name cannot be empty")
        }
        
        // Validate schema version is not empty
        guard !schema.version.isEmpty else {
            throw FTAIParseError.invalidSchema("Schema version cannot be empty")
        }
        
        // Validate field names are unique
        let fieldNames = schema.fields.map { $0.name }
        let uniqueFieldNames = Set(fieldNames)
        guard fieldNames.count == uniqueFieldNames.count else {
            throw FTAIParseError.invalidSchema("Duplicate field names in schema")
        }
        
        // Validate field names are not empty
        for field in schema.fields {
            guard !field.name.isEmpty else {
                throw FTAIParseError.invalidSchema("Field name cannot be empty")
            }
        }
    }
}