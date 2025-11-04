import XCTest
@testable import SerenaNet

final class FTAIParserTests: XCTestCase {
    
    var parser: FTAIParser!
    
    override func setUp() {
        super.setUp()
        parser = FTAIParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Basic Parsing Tests
    
    func testParseSimpleDocument() throws {
        let ftaiContent = """
        version: 1.0
        title: Test Document
        author: Test Author
        
        content:
        This is a simple FTAI document for testing.
        It contains multiple lines of content.
        """
        
        let document = try parser.parse(ftaiContent)
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertEqual(document.metadata["title"], "Test Document")
        XCTAssertEqual(document.metadata["author"], "Test Author")
        XCTAssertTrue(document.content.contains("This is a simple FTAI document"))
        XCTAssertNil(document.schema)
    }
    
    func testParseDocumentWithSchema() throws {
        let ftaiContent = """
        version: 1.0
        title: Document with Schema
        
        schema:
        name: TestSchema
        version: 1.0
        description: A test schema
        field: name:string:true:User name
        field: age:integer:false:User age
        field: active:boolean:true:User status
        
        content:
        This document has a schema definition.
        """
        
        let document = try parser.parse(ftaiContent)
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertEqual(document.metadata["title"], "Document with Schema")
        
        XCTAssertNotNil(document.schema)
        let schema = document.schema!
        XCTAssertEqual(schema.name, "TestSchema")
        XCTAssertEqual(schema.version, "1.0")
        XCTAssertEqual(schema.description, "A test schema")
        XCTAssertEqual(schema.fields.count, 3)
        
        // Test first field
        let nameField = schema.fields[0]
        XCTAssertEqual(nameField.name, "name")
        XCTAssertEqual(nameField.type, .string)
        XCTAssertTrue(nameField.required)
        XCTAssertEqual(nameField.description, "User name")
        
        // Test second field
        let ageField = schema.fields[1]
        XCTAssertEqual(ageField.name, "age")
        XCTAssertEqual(ageField.type, .integer)
        XCTAssertFalse(ageField.required)
        XCTAssertEqual(ageField.description, "User age")
        
        // Test third field
        let activeField = schema.fields[2]
        XCTAssertEqual(activeField.name, "active")
        XCTAssertEqual(activeField.type, .boolean)
        XCTAssertTrue(activeField.required)
        XCTAssertEqual(activeField.description, "User status")
    }
    
    func testParseDocumentWithComments() throws {
        let ftaiContent = """
        # This is a comment
        version: 1.0
        # Another comment
        title: Test Document
        
        # Comment before content
        content:
        This is the content.
        # This comment should be included in content
        More content here.
        """
        
        let document = try parser.parse(ftaiContent)
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertEqual(document.metadata["title"], "Test Document")
        XCTAssertTrue(document.content.contains("This is the content."))
        XCTAssertTrue(document.content.contains("# This comment should be included in content"))
        XCTAssertTrue(document.content.contains("More content here."))
    }
    
    // MARK: - Error Handling Tests
    
    func testParseEmptyContent() {
        let ftaiContent = ""
        
        XCTAssertThrowsError(try parser.parse(ftaiContent)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError, got: \(error)")
                return
            }
            
            if case .invalidFormat(let details) = parseError {
                XCTAssertEqual(details, "Empty content")
            } else {
                XCTFail("Expected invalidFormat error, got: \(parseError)")
            }
        }
    }
    
    func testParseMissingVersion() {
        let ftaiContent = """
        title: Test Document
        
        content:
        This document is missing a version.
        """
        
        XCTAssertThrowsError(try parser.parse(ftaiContent)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .missingVersion = parseError {
                // Expected error
            } else {
                XCTFail("Expected missingVersion error")
            }
        }
    }
    
    func testParseUnsupportedVersion() {
        let ftaiContent = """
        version: 2.0
        title: Future Document
        
        content:
        This document uses an unsupported version.
        """
        
        XCTAssertThrowsError(try parser.parse(ftaiContent)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .unsupportedVersion(let version) = parseError {
                XCTAssertEqual(version, "2.0")
            } else {
                XCTFail("Expected unsupportedVersion error")
            }
        }
    }
    
    func testParseInvalidSchema() {
        let ftaiContent = """
        version: 1.0
        title: Invalid Schema Document
        
        schema:
        name: TestSchema
        field: :string:true:Invalid field name
        
        content:
        This document has an invalid schema.
        """
        
        XCTAssertThrowsError(try parser.parse(ftaiContent)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .invalidSchema = parseError {
                // Expected error
            } else {
                XCTFail("Expected invalidSchema error")
            }
        }
    }
    
    func testParseUnknownFieldType() {
        let ftaiContent = """
        version: 1.0
        title: Unknown Field Type Document
        
        schema:
        name: TestSchema
        version: 1.0
        field: test:unknown:true:Unknown field type
        
        content:
        This document has an unknown field type.
        """
        
        XCTAssertThrowsError(try parser.parse(ftaiContent)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .invalidSchema(let details) = parseError {
                XCTAssertTrue(details.contains("Unknown field type: unknown"))
            } else {
                XCTFail("Expected invalidSchema error with unknown field type")
            }
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidDocument() throws {
        let document = FTAIDocument(
            version: "1.0",
            metadata: ["title": "Test"],
            content: "Valid content"
        )
        
        XCTAssertTrue(try parser.validate(document))
    }
    
    func testValidateUnsupportedVersion() {
        let document = FTAIDocument(
            version: "3.0",
            metadata: ["title": "Test"],
            content: "Content"
        )
        
        XCTAssertThrowsError(try parser.validate(document)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .unsupportedVersion(let version) = parseError {
                XCTAssertEqual(version, "3.0")
            } else {
                XCTFail("Expected unsupportedVersion error")
            }
        }
    }
    
    func testValidateEmptyContent() {
        let document = FTAIDocument(
            version: "1.0",
            metadata: ["title": "Test"],
            content: "   \n  \t  "
        )
        
        XCTAssertThrowsError(try parser.validate(document)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .missingContent = parseError {
                // Expected error
            } else {
                XCTFail("Expected missingContent error")
            }
        }
    }
    
    func testValidateSchemaWithDuplicateFields() {
        let schema = FTAISchema(
            name: "TestSchema",
            version: "1.0",
            fields: [
                FTAIField(name: "field1", type: .string),
                FTAIField(name: "field1", type: .integer) // Duplicate name
            ]
        )
        
        let document = FTAIDocument(
            version: "1.0",
            metadata: ["title": "Test"],
            content: "Content",
            schema: schema
        )
        
        XCTAssertThrowsError(try parser.validate(document)) { error in
            guard let parseError = error as? FTAIParser.FTAIParseError else {
                XCTFail("Expected FTAIParseError")
                return
            }
            
            if case .invalidSchema(let details) = parseError {
                XCTAssertTrue(details.contains("Duplicate field names"))
            } else {
                XCTFail("Expected invalidSchema error for duplicate fields")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testParseDocumentWithOnlyVersion() throws {
        let ftaiContent = """
        version: 1.0
        
        content:
        
        """
        
        let document = try parser.parse(ftaiContent)
        
        XCTAssertEqual(document.version, "1.0")
        XCTAssertTrue(document.metadata.isEmpty)
        XCTAssertEqual(document.content, "")
        XCTAssertNil(document.schema)
    }
    
    func testParseDocumentWithMultipleMetadata() throws {
        let ftaiContent = """
        version: 1.1
        title: Multi Metadata Document
        author: John Doe
        category: Test
        priority: High
        tags: test, parsing, ftai
        
        content:
        Document with multiple metadata fields.
        """
        
        let document = try parser.parse(ftaiContent)
        
        XCTAssertEqual(document.version, "1.1")
        XCTAssertEqual(document.metadata.count, 5)
        XCTAssertEqual(document.metadata["title"], "Multi Metadata Document")
        XCTAssertEqual(document.metadata["author"], "John Doe")
        XCTAssertEqual(document.metadata["category"], "Test")
        XCTAssertEqual(document.metadata["priority"], "High")
        XCTAssertEqual(document.metadata["tags"], "test, parsing, ftai")
    }
    
    func testParseDocumentWithAllFieldTypes() throws {
        let ftaiContent = """
        version: 1.0
        title: All Field Types
        
        schema:
        name: CompleteSchema
        version: 1.0
        field: stringField:string:true:A string field
        field: intField:integer:false:An integer field
        field: boolField:boolean:true:A boolean field
        field: arrayField:array:false:An array field
        field: objectField:object:false:An object field
        field: dateField:date:true:A date field
        
        content:
        Document with all supported field types.
        """
        
        let document = try parser.parse(ftaiContent)
        let schema = document.schema!
        
        XCTAssertEqual(schema.fields.count, 6)
        
        let fieldTypes = schema.fields.map { $0.type }
        XCTAssertTrue(fieldTypes.contains(.string))
        XCTAssertTrue(fieldTypes.contains(.integer))
        XCTAssertTrue(fieldTypes.contains(.boolean))
        XCTAssertTrue(fieldTypes.contains(.array))
        XCTAssertTrue(fieldTypes.contains(.object))
        XCTAssertTrue(fieldTypes.contains(.date))
    }
    
    // MARK: - Model Tests
    
    func testFTAIDocumentEquality() {
        let schema = FTAISchema(name: "Test", version: "1.0", fields: [])
        let doc1 = FTAIDocument(version: "1.0", metadata: ["title": "Test"], content: "Content", schema: schema)
        let doc2 = FTAIDocument(version: "1.0", metadata: ["title": "Test"], content: "Content", schema: schema)
        
        XCTAssertEqual(doc1.version, doc2.version)
        XCTAssertEqual(doc1.metadata, doc2.metadata)
        XCTAssertEqual(doc1.content, doc2.content)
        XCTAssertEqual(doc1.schema, doc2.schema)
    }
    
    func testFTAIFieldTypeDisplayNames() {
        XCTAssertEqual(FTAIFieldType.string.displayName, "String")
        XCTAssertEqual(FTAIFieldType.integer.displayName, "Integer")
        XCTAssertEqual(FTAIFieldType.boolean.displayName, "Boolean")
        XCTAssertEqual(FTAIFieldType.array.displayName, "Array")
        XCTAssertEqual(FTAIFieldType.object.displayName, "Object")
        XCTAssertEqual(FTAIFieldType.date.displayName, "Date")
    }
    
    func testFTAIFieldInitialization() {
        let field = FTAIField(name: "testField", type: .string, required: true, description: "Test field")
        
        XCTAssertEqual(field.name, "testField")
        XCTAssertEqual(field.type, .string)
        XCTAssertTrue(field.required)
        XCTAssertEqual(field.description, "Test field")
    }
    
    func testFTAISchemaInitialization() {
        let fields = [
            FTAIField(name: "field1", type: .string),
            FTAIField(name: "field2", type: .integer)
        ]
        
        let schema = FTAISchema(name: "TestSchema", version: "1.0", fields: fields, description: "Test schema")
        
        XCTAssertEqual(schema.name, "TestSchema")
        XCTAssertEqual(schema.version, "1.0")
        XCTAssertEqual(schema.fields.count, 2)
        XCTAssertEqual(schema.description, "Test schema")
    }
}