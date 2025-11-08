import XCTest
@testable import SerenaCore

@MainActor
final class LocalEmbeddingServiceTests: XCTestCase {

    func testEmbeddingServiceInitialization() async throws {
        print("🧪 Test 1: Initializing LocalEmbeddingService...")

        let service = LocalEmbeddingService.shared
        XCTAssertFalse(service.isReady, "Service should not be ready before initialization")

        let startInit = Date()
        try await service.initialize()
        let initTime = Date().timeIntervalSince(startInit) * 1000

        print("✅ Initialized in \(String(format: "%.2f", initTime))ms")
        XCTAssertTrue(service.isReady, "Service should be ready after initialization")
    }

    func testSingleEmbeddingGeneration() async throws {
        print("\n🧪 Test 2: Generating single embedding...")

        let service = LocalEmbeddingService.shared
        try await service.initialize()

        let startEmbed = Date()
        let embedding = try await service.embed(text: "hello world")
        let embedTime = Date().timeIntervalSince(startEmbed) * 1000

        print("✅ Generated embedding in \(String(format: "%.2f", embedTime))ms")
        print("   Dimension: \(embedding.count)")
        print("   First 5 values: \(embedding.prefix(5))")

        XCTAssertEqual(embedding.count, 384, "Embedding should be 384-dimensional")
        XCTAssertFalse(embedding.allSatisfy { $0 == 0 }, "Embedding should not be all zeros")
    }

    func testMultipleEmbeddings() async throws {
        print("\n🧪 Test 3: Generating multiple embeddings...")

        let service = LocalEmbeddingService.shared
        try await service.initialize()

        let embed1 = try await service.embed(text: "hello world")
        let embed2 = try await service.embed(text: "goodbye world")

        print("✅ Generated 2 embeddings")

        XCTAssertEqual(embed1.count, 384)
        XCTAssertEqual(embed2.count, 384)
        XCTAssertNotEqual(embed1, embed2, "Different texts should produce different embeddings")
    }

    func testCosineSimilarity() async throws {
        print("\n🧪 Test 4: Testing cosine similarity...")

        let service = LocalEmbeddingService.shared
        try await service.initialize()

        let embed1 = try await service.embed(text: "hello world")
        let embed2 = try await service.embed(text: "goodbye world")
        let embed3 = try await service.embed(text: "hello world")

        let similarity12 = service.cosineSimilarity(embed1, embed2)
        let similarity13 = service.cosineSimilarity(embed1, embed3)

        print("✅ Similarity 'hello world' vs 'goodbye world': \(similarity12)")
        print("✅ Similarity 'hello world' vs 'hello world': \(similarity13)")

        XCTAssertGreaterThan(similarity13, similarity12, "Identical texts should have higher similarity")
        XCTAssertGreaterThan(similarity13, 0.9, "Identical texts should have very high similarity")
    }

    func testBatchEmbedding() async throws {
        print("\n🧪 Test 5: Testing batch embedding...")

        let service = LocalEmbeddingService.shared
        try await service.initialize()

        let texts = ["hello", "world", "test", "embedding", "service"]

        let startBatch = Date()
        let embeddings = try await service.batchEmbed(texts: texts)
        let batchTime = Date().timeIntervalSince(startBatch) * 1000

        print("✅ Batch embedded \(texts.count) texts in \(String(format: "%.2f", batchTime))ms")
        print("   Avg per text: \(String(format: "%.2f", batchTime / Double(texts.count)))ms")

        XCTAssertEqual(embeddings.count, texts.count, "Should generate one embedding per text")
        for embedding in embeddings {
            XCTAssertEqual(embedding.count, 384, "Each embedding should be 384-dimensional")
        }
    }

    func testPerformanceBenchmark() async throws {
        print("\n🧪 Test 6: Performance benchmark...")

        let service = LocalEmbeddingService.shared
        try await service.initialize()

        // Warmup
        _ = try await service.embed(text: "warmup")

        // Measure 10 embeddings
        var times: [Double] = []
        for i in 1...10 {
            let start = Date()
            _ = try await service.embed(text: "test embedding \(i)")
            let time = Date().timeIntervalSince(start) * 1000
            times.append(time)
        }

        let avgTime = times.reduce(0, +) / Double(times.count)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0

        print("✅ Performance metrics:")
        print("   Average: \(String(format: "%.2f", avgTime))ms")
        print("   Min: \(String(format: "%.2f", minTime))ms")
        print("   Max: \(String(format: "%.2f", maxTime))ms")

        XCTAssertLessThan(avgTime, 100, "Average embedding time should be under 100ms")
    }
}
