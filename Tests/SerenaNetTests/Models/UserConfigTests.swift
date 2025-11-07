import XCTest
@testable import SerenaNet

final class UserConfigTests: XCTestCase {
    
    func testUserConfigDefaults() {
        let config = UserConfig.default
        
        XCTAssertEqual(config.nickname, "User")
        XCTAssertEqual(config.theme, .system)
        XCTAssertTrue(config.voiceInputEnabled)
        XCTAssertFalse(config.passcodeEnabled)
        XCTAssertEqual(config.aiParameters, AIParameters.default)
    }
    
    func testAppThemeDisplayNames() {
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        XCTAssertEqual(AppTheme.system.displayName, "System")
    }
    
    func testAppThemeColorSchemes() {
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
        XCTAssertNil(AppTheme.system.colorScheme)
    }
    
    func testAIParametersDefaults() {
        let params = AIParameters.default
        
        XCTAssertEqual(params.temperature, 0.7)
        XCTAssertEqual(params.maxTokens, 1000)
        XCTAssertEqual(params.contextWindow, 10)
    }
    
    func testAIParametersValidation() {
        // Test temperature bounds
        let highTemp = AIParameters(temperature: 3.0, maxTokens: 1000, contextWindow: 10)
        XCTAssertEqual(highTemp.temperature, 2.0)
        
        let lowTemp = AIParameters(temperature: -1.0, maxTokens: 1000, contextWindow: 10)
        XCTAssertEqual(lowTemp.temperature, 0.0)
        
        // Test maxTokens bounds
        let highTokens = AIParameters(temperature: 0.7, maxTokens: 5000, contextWindow: 10)
        XCTAssertEqual(highTokens.maxTokens, 4000)
        
        let lowTokens = AIParameters(temperature: 0.7, maxTokens: 50, contextWindow: 10)
        XCTAssertEqual(lowTokens.maxTokens, 100)
        
        // Test contextWindow bounds
        let highContext = AIParameters(temperature: 0.7, maxTokens: 1000, contextWindow: 25)
        XCTAssertEqual(highContext.contextWindow, 20)
        
        let lowContext = AIParameters(temperature: 0.7, maxTokens: 1000, contextWindow: 0)
        XCTAssertEqual(lowContext.contextWindow, 1)
    }
    
    func testUserConfigCodable() throws {
        let config = UserConfig(
            nickname: "TestUser",
            theme: .dark,
            voiceInputEnabled: false,
            passcodeEnabled: true,
            aiParameters: AIParameters(temperature: 0.5, maxTokens: 500, contextWindow: 5)
        )
        
        let encoded = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(UserConfig.self, from: encoded)
        
        XCTAssertEqual(config, decoded)
    }
}