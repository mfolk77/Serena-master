import XCTest
@testable import SerenaNet

final class FTAIDocumentTests: XCTestCase {
    
    // MARK: - FTAIDocument Tests
    
    func testFTAIDocumentInitialization() {
        let metadata = ["title": "Test Document", "author": "Test Author"]
        let schema = FTAISchema(name: "TestSchema", version: "1.0", fields: [])
        
        let document = FTAIDocument(
            version: "1.0",
            metadata: metadata,
            content: "Test content",
            schema: schema
        )
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertEqual(document.metadata, metadata)
        XCTAssertEqual(document.content, "Test content")
        XCTAssertEqual(document.schema, schema)
        XCTAssertNotNil(document.createdAt)
    }
    
    func testFTAIDocumentDefaultInitialization() {
        let document = FTAIDocument(version: "1.0", content: "Test content")
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertTrue(document.metadata.isEmpty)
        XCTAssertEqual(document.content, "Test content")
        XCTAssertNil(document.schema)
        XCTAssertNotNil(document.createdAt)
    }
    
    func testFTAIDocumentCodable() throws {
        let originalDocument = FTAIDocument(
            version: "1.0",
            metadata: ["title": "Test"],
            content: "Test content"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalDocument)
        
        let decoder = JSONDecoder()
        let decodedDocument = try decoder.decode(FTAIDocument.self, from: data)
        
        XCTAssertEqual(originalDocument.version, decodedDocument.version)
        XCTAssertEqual(originalDocument.metadata, decodedDocument.metadata)
        XCTAssertEqual(originalDocument.content, decodedDocument.content)
        XCTAssertEqual(originalDocument.schema, decodedDocument.schema)
    }
    
    func testFTAIDocumentEquality() {
        let schema = FTAISchema(name: "Test", version: "1.0", fields: [])
        let metadata = ["title": "Test"]
        
        let document1 = FTAIDocument(
            version: "1.0",
            metadata: metadata,
            content: "Content",
            schema: schema
        )
        
        let document2 = FTAIDocument(
            version: "1.0",
            metadata: metadata,
            content: "Content",
            schema: schema
        )
        
        // Note: These won't be equal due to different createdAt timestamps
        // But we can test individual properties
        XCTAssertEqual(document1.version, document2.version)
        XCTAssertEqual(document1.metadata, document2.metadata)
        XCTAssertEqual(document1.content, document2.content)
        XCTAssertEqual(document1.schema, document2.schema)
    }
    
    // MARK: - FTAISchema Tests
    
    func testFTAISchemaInitialization() {
        let fields = [
            FTAIField(name: "field1", type: .string, required: true),
            FTAIField(name: "field2", type: .integer, required: false)
        ]
        
        let schema = FTAISchema(
            name: "TestSchema",
            version: "1.0",
            fields: fields,
            description: "A test schema"
        )
        
        XCTAssertEqual(schema.name, "TestSchema")
        XCTAssertEqual(schema.version, "1.0")
        XCTAssertEqual(schema.fields.count, 2)
        XCTAssertEqual(schema.description, "A test schema")
    }
    
    func testFTAISchemaDefaultInitialization() {
        let schema = FTAISchema(name: "TestSchema", version: "1.0", fields: [])
        
        XCTAssertEqual(schema.name, "TestSchema")
        XCTAssertEqual(schema.version, "1.0")
        XCTAssertTrue(schema.fields.isEmpty)
        XCTAssertNil(schema.description)
    }
    
    func testFTAISchemaCodable() throws {
        let fields = [FTAIField(name: "test", type: .string)]
        let originalSchema = FTAISchema(
            name: "TestSchema",
            version: "1.0",
            fields: fields,
            description: "Test"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSchema)
        
        let decoder = JSONDecoder()
        let decodedSchema = try decoder.decode(FTAISchema.self, from: data)
        
        XCTAssertEqual(originalSchema, decodedSchema)
    }
    
    func testFTAISchemaEquality() {
        let fields1 = [FTAIField(name: "field1", type: .string)]
        let fields2 = [FTAIField(name: "field1", type: .string)]
        
        let schema1 = FTAISchema(name: "Test", version: "1.0", fields: fields1)
        let schema2 = FTAISchema(name: "Test", version: "1.0", fields: fields2)
        
        XCTAssertEqual(schema1, schema2)
    }
    
    // MARK: - FTAIField Tests
    
    func testFTAIFieldInitialization() {
        let field = FTAIField(
            name: "testField",
            type: .string,
            required: true,
            description: "A test field"
        )
        
        XCTAssertEqual(field.name, "testField")
        XCTAssertEqual(field.type, .string)
        XCTAssertTrue(field.required)
        XCTAssertEqual(field.description, "A test field")
    }
    
    func testFTAIFieldDefaultInitialization() {
        let field = FTAIField(name: "testField", type: .string)
        
        XCTAssertEqual(field.name, "testField")
        XCTAssertEqual(field.type, .string)
        XCTAssertFalse(field.required)
        XCTAssertNil(field.description)
    }
    
    func testFTAIFieldCodable() throws {
        let originalField = FTAIField(
            name: "testField",
            type: .boolean,
            required: true,
            description: "Test field"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalField)
        
        let decoder = JSONDecoder()
        let decodedField = try decoder.decode(FTAIField.self, from: data)
        
        XCTAssertEqual(originalField, decodedField)
    }
    
    func testFTAIFieldEquality() {
        let field1 = FTAIField(name: "test", type: .string, required: true, description: "Test")
        let field2 = FTAIField(name: "test", type: .string, required: true, description: "Test")
        
        XCTAssertEqual(field1, field2)
    }
    
    // MARK: - FTAIFieldType Tests
    
    func testFTAIFieldTypeRawValues() {
        XCTAssertEqual(FTAIFieldType.string.rawValue, "string")
        XCTAssertEqual(FTAIFieldType.integer.rawValue, "integer")
        XCTAssertEqual(FTAIFieldType.boolean.rawValue, "boolean")
        XCTAssertEqual(FTAIFieldType.array.rawValue, "array")
        XCTAssertEqual(FTAIFieldType.object.rawValue, "object")
        XCTAssertEqual(FTAIFieldType.date.rawValue, "date")
    }
    
    func testFTAIFieldTypeDisplayNames() {
        XCTAssertEqual(FTAIFieldType.string.displayName, "String")
        XCTAssertEqual(FTAIFieldType.integer.displayName, "Integer")
        XCTAssertEqual(FTAIFieldType.boolean.displayName, "Boolean")
        XCTAssertEqual(FTAIFieldType.array.displayName, "Array")
        XCTAssertEqual(FTAIFieldType.object.displayName, "Object")
        XCTAssertEqual(FTAIFieldType.date.displayName, "Date")
    }
    
    func testFTAIFieldTypeCaseIterable() {
        let allCases = FTAIFieldType.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.string))
        XCTAssertTrue(allCases.contains(.integer))
        XCTAssertTrue(allCases.contains(.boolean))
        XCTAssertTrue(allCases.contains(.array))
        XCTAssertTrue(allCases.contains(.object))
        XCTAssertTrue(allCases.contains(.date))
    }
    
    func testFTAIFieldTypeFromRawValue() {
        XCTAssertEqual(FTAIFieldType(rawValue: "string"), .string)
        XCTAssertEqual(FTAIFieldType(rawValue: "integer"), .integer)
        XCTAssertEqual(FTAIFieldType(rawValue: "boolean"), .boolean)
        XCTAssertEqual(FTAIFieldType(rawValue: "array"), .array)
        XCTAssertEqual(FTAIFieldType(rawValue: "object"), .object)
        XCTAssertEqual(FTAIFieldType(rawValue: "date"), .date)
        XCTAssertNil(FTAIFieldType(rawValue: "unknown"))
    }
    
    func testFTAIFieldTypeCodable() throws {
        let fieldType = FTAIFieldType.string
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(fieldType)
        
        let decoder = JSONDecoder()
        let decodedFieldType = try decoder.decode(FTAIFieldType.self, from: data)
        
        XCTAssertEqual(fieldType, decodedFieldType)
    }
}