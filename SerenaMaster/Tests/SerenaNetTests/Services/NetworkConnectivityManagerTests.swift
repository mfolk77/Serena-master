import XCTest
import Network
@testable import SerenaNet

@MainActor
final class NetworkConnectivityManagerTests: XCTestCase {
    var networkManager: NetworkConnectivityManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkConnectivityManager()
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    // MARK: - Feature Availability Tests
    
    func testLocalAIAlwaysAvailable() {
        // Local AI should always be available regardless of network status
        XCTAssertTrue(networkManager.isFeatureAvailable(.localAI))
        
        // Even if we simulate offline mode
        // (Note: In real implementation, we'd need to mock the network monitor)
        XCTAssertTrue(networkManager.isFeatureAvailable(.localAI))
    }
    
    func testVoiceInputAlwaysAvailable() {
        // Voice input should always be available (uses local speech recognition)
        XCTAssertTrue(networkManager.isFeatureAvailable(.voiceInput))
    }
    
    func testNetworkDependentFeatures() {
        // These features depend on network connectivity
        // In a real test, we'd mock the network state
        let networkFeatures: [NetworkFeature] = [.dataSync, .updates, .externalAPIs]
        
        for feature in networkFeatures {
            // When connected, these should be available
            if networkManager.isConnected {
                XCTAssertTrue(networkManager.isFeatureAvailable(feature))
            }
            // When offline, these should be unavailable
            // (We can't easily test offline state without mocking)
        }
    }
    
    // MARK: - Status Message Tests
    
    func testStatusMessageFormat() {
        let statusMessage = networkManager.getStatusMessage()
        XCTAssertFalse(statusMessage.isEmpty)
        
        // Should contain connection information
        if networkManager.isConnected {
            XCTAssertTrue(statusMessage.contains("Connected"))
        } else {
            XCTAssertTrue(statusMessage.contains("Offline"))
        }
    }
    
    func testOfflineModeGuidance() {
        let guidance = networkManager.getOfflineModeGuidance()
        XCTAssertFalse(guidance.isEmpty)
        
        if !networkManager.isConnected {
            XCTAssertTrue(guidance.contains("offline"))
            XCTAssertTrue(guidance.contains("locally"))
        }
    }
    
    // MARK: - Network Quality Tests
    
    func testNetworkQualityAssessment() {
        let quality = networkManager.getNetworkQuality()
        
        // Should return a valid quality level
        let validQualities: [NetworkQuality] = [.offline, .poor, .limited, .good, .excellent, .unknown]
        XCTAssertTrue(validQualities.contains(quality))
    }
    
    func testNetworkQualityDescription() {
        let allQualities: [NetworkQuality] = [.offline, .poor, .limited, .good, .excellent, .unknown]
        
        for quality in allQualities {
            XCTAssertFalse(quality.description.isEmpty)
            XCTAssertFalse(quality.systemImageName.isEmpty)
        }
    }
    
    func testSuitabilityForLargeOperations() {
        let isSuitable = networkManager.isSuitableForLargeOperations()
        let quality = networkManager.getNetworkQuality()
        
        // Should be suitable for excellent or good connections
        if quality == .excellent || quality == .good {
            XCTAssertTrue(isSuitable)
        } else if quality == .offline || quality == .poor {
            XCTAssertFalse(isSuitable)
        }
    }
    
    // MARK: - Offline Operation Validation Tests
    
    func testOfflineOperationValidation() throws {
        // AI inference should always be valid
        XCTAssertNoThrow(try networkManager.validateOfflineOperation(.aiInference))
        
        // Voice recognition should always be valid
        XCTAssertNoThrow(try networkManager.validateOfflineOperation(.voiceRecognition))
        
        // Data storage should always be valid
        XCTAssertNoThrow(try networkManager.validateOfflineOperation(.dataStorage))
        
        // Data sync should throw when offline
        if !networkManager.isConnected {
            XCTAssertThrowsError(try networkManager.validateOfflineOperation(.dataSync)) { error in
                XCTAssertTrue(error is SerenaError)
                if case SerenaError.networkUnavailable = error {
                    // Expected error
                } else {
                    XCTFail("Expected networkUnavailable error")
                }
            }
        }
    }
    
    // MARK: - Fallback Operation Tests
    
    func testPerformWithFallback() async throws {
        let networkOperation: () async throws -> String = {
            return "network_result"
        }
        
        let offlineFallback: () async throws -> String = {
            return "offline_result"
        }
        
        let result = try await networkManager.performWithFallback(
            networkOperation: networkOperation,
            offlineFallback: offlineFallback
        )
        
        // Should return either network or offline result
        XCTAssertTrue(result == "network_result" || result == "offline_result")
        
        if networkManager.isConnected {
            XCTAssertEqual(result, "network_result")
        } else {
            XCTAssertEqual(result, "offline_result")
        }
    }
    
    func testPerformWithFallbackOnNetworkFailure() async throws {
        let networkOperation: () async throws -> String = {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        
        let offlineFallback: () async throws -> String = {
            return "fallback_result"
        }
        
        let result = try await networkManager.performWithFallback(
            networkOperation: networkOperation,
            offlineFallback: offlineFallback
        )
        
        // Should fall back to offline result when network operation fails
        XCTAssertEqual(result, "fallback_result")
    }
    
    // MARK: - Offline Capabilities Tests
    
    func testOfflineCapabilities() {
        let capabilities = networkManager.offlineCapabilities
        
        // Should have full capabilities since AI runs locally
        XCTAssertEqual(capabilities, .full)
        
        // Description should not be empty
        XCTAssertFalse(capabilities.description.isEmpty)
    }
}

// MARK: - Supporting Types Tests

final class NetworkQualityTests: XCTestCase {
    
    func testNetworkQualityDescriptions() {
        let qualities: [NetworkQuality] = [.offline, .poor, .limited, .good, .excellent, .unknown]
        
        for quality in qualities {
            XCTAssertFalse(quality.description.isEmpty)
            XCTAssertFalse(quality.systemImageName.isEmpty)
        }
    }
    
    func testNetworkQualitySystemImages() {
        XCTAssertEqual(NetworkQuality.offline.systemImageName, "wifi.slash")
        XCTAssertEqual(NetworkQuality.poor.systemImageName, "wifi.exclamationmark")
        XCTAssertEqual(NetworkQuality.limited.systemImageName, "wifi")
        XCTAssertEqual(NetworkQuality.good.systemImageName, "wifi")
        XCTAssertEqual(NetworkQuality.excellent.systemImageName, "wifi")
        XCTAssertEqual(NetworkQuality.unknown.systemImageName, "questionmark.circle")
    }
}

final class OfflineCapabilitiesTests: XCTestCase {
    
    func testOfflineCapabilitiesDescriptions() {
        XCTAssertEqual(OfflineCapabilities.full.description, "All features available")
        XCTAssertEqual(OfflineCapabilities.limited.description, "Some features unavailable")
        XCTAssertEqual(OfflineCapabilities.minimal.description, "Basic features only")
    }
}

final class NWInterfaceTypeExtensionTests: XCTestCase {
    
    func testInterfaceTypeDescriptions() {
        XCTAssertEqual(NWInterface.InterfaceType.wifi.description, "Wi-Fi")
        XCTAssertEqual(NWInterface.InterfaceType.cellular.description, "Cellular")
        XCTAssertEqual(NWInterface.InterfaceType.wiredEthernet.description, "Ethernet")
        XCTAssertEqual(NWInterface.InterfaceType.loopback.description, "Loopback")
        XCTAssertEqual(NWInterface.InterfaceType.other.description, "Other")
    }
}