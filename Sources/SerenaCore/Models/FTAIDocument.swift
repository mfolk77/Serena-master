import Foundation

/// Represents a parsed FTAI document with metadata and content
public struct FTAIDocument: Codable, Equatable {
    public let version: String
    public let metadata: [String: String]
    public let content: String
    public let schema: FTAISchema?
    public let createdAt: Date
    
    public init(version: String, metadata: [String: String] = [:], content: String, schema: FTAISchema? = nil) {
        self.version = version
        self.metadata = metadata
        self.content = content
        self.schema = schema
        self.createdAt = Date()
    }
}

/// Represents the schema definition for FTAI documents
public struct FTAISchema: Codable, Equatable {
    let name: String
    let version: String
    let fields: [FTAIField]
    let description: String?
    
    init(name: String, version: String, fields: [FTAIField], description: String? = nil) {
        self.name = name
        self.version = version
        self.fields = fields
        self.description = description
    }
}

/// Represents a field definition in an FTAI schema
public struct FTAIField: Codable, Equatable {
    let name: String
    let type: FTAIFieldType
    let required: Bool
    let description: String?
    
    init(name: String, type: FTAIFieldType, required: Bool = false, description: String? = nil) {
        self.name = name
        self.type = type
        self.required = required
        self.description = description
    }
}

/// Supported field types in FTAI schemas
public enum FTAIFieldType: String, Codable, CaseIterable {
    case string
    case integer
    case boolean
    case array
    case object
    case date
    
    var displayName: String {
        switch self {
        case .string:
            return "String"
        case .integer:
            return "Integer"
        case .boolean:
            return "Boolean"
        case .array:
            return "Array"
        case .object:
            return "Object"
        case .date:
            return "Date"
        }
    }
}