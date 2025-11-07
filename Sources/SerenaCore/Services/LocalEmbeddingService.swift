import Foundation
import CoreML
import os.log

/// Local embedding service that uses the CoreML sentence-transformer model
/// for generating text embeddings completely offline.
@MainActor
public class LocalEmbeddingService: ObservableObject {

    // MARK: - Singleton
    public static let shared = LocalEmbeddingService()

    // MARK: - Properties
    @Published public private(set) var isReady: Bool = false
    @Published public private(set) var isLoading: Bool = false

    private var mlModel: MLModel?
    private let logger = Logger(subsystem: "com.folktech.serena", category: "LocalEmbeddingService")

    // Model configuration
    private let modelPath: URL
    private let maxTokens: Int = 128
    private let embeddingDimension: Int = 384 // all-MiniLM-L6-v2 produces 384-dimensional embeddings

    // MARK: - Initialization
    private init() {
        // Path to the compiled CoreML model
        self.modelPath = URL(fileURLWithPath: "/Volumes/Folk_DAS/Developer/Serena/Models/embedding_model.mlmodelc")
        logger.info("LocalEmbeddingService initialized with model path: \(self.modelPath.path)")
    }

    // MARK: - Public Methods

    /// Initialize the embedding model
    public func initialize() async throws {
        guard !isReady else {
            logger.info("Embedding service already initialized")
            return
        }

        isLoading = true
        logger.info("Starting embedding model initialization...")

        do {
            // Check if model file exists
            guard FileManager.default.fileExists(atPath: modelPath.path) else {
                throw EmbeddingError.modelNotFound(modelPath.path)
            }

            // Load the compiled CoreML model
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all // Use Neural Engine, GPU, and CPU

            logger.info("Loading CoreML model from: \(self.modelPath.path)")
            mlModel = try await Task.detached {
                try MLModel(contentsOf: self.modelPath, configuration: configuration)
            }.value

            isReady = true
            isLoading = false
            logger.info("✅ Embedding model loaded successfully")

        } catch {
            isReady = false
            isLoading = false
            logger.error("❌ Failed to load embedding model: \(error.localizedDescription)")
            throw EmbeddingError.initializationFailed(error.localizedDescription)
        }
    }

    /// Generate embeddings for the given text
    /// - Parameter text: Input text to embed
    /// - Returns: Array of floats representing the embedding vector (384 dimensions)
    public func embed(text: String) async throws -> [Float] {
        guard isReady, let model = mlModel else {
            throw EmbeddingError.modelNotReady
        }

        logger.info("Generating embedding for text: '\(text.prefix(50))...'")

        do {
            // Tokenize the input text
            let (inputIds, attentionMask) = try tokenize(text: text)

            // Create MLMultiArray inputs for the model
            let inputIdsArray = try createMLMultiArray(from: inputIds)
            let attentionMaskArray = try createMLMultiArray(from: attentionMask)

            // Create model input
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLFeatureValue(multiArray: inputIdsArray),
                "attention_mask": MLFeatureValue(multiArray: attentionMaskArray)
            ])

            // Run inference
            let output = try await Task.detached {
                try model.prediction(from: input)
            }.value

            // Extract embedding from output
            // The model outputs a tensor, we need to extract the [CLS] token embedding
            guard let outputFeature = output.featureValue(for: "output_0"),
                  let multiArray = outputFeature.multiArrayValue else {
                throw EmbeddingError.invalidOutput
            }

            // Convert MLMultiArray to [Float]
            let embedding = try extractEmbedding(from: multiArray)

            logger.info("✅ Generated \(embedding.count)-dimensional embedding")
            return embedding

        } catch {
            logger.error("❌ Embedding generation failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Batch embed multiple texts
    /// - Parameter texts: Array of texts to embed
    /// - Returns: Array of embedding vectors
    public func batchEmbed(texts: [String]) async throws -> [[Float]] {
        logger.info("Batch embedding \(texts.count) texts")

        var embeddings: [[Float]] = []

        for text in texts {
            let embedding = try await embed(text: text)
            embeddings.append(embedding)
        }

        return embeddings
    }

    /// Calculate cosine similarity between two embeddings
    /// - Parameters:
    ///   - embedding1: First embedding vector
    ///   - embedding2: Second embedding vector
    /// - Returns: Similarity score between -1 and 1
    public func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else {
            logger.error("Embedding dimensions don't match: \(embedding1.count) vs \(embedding2.count)")
            return 0
        }

        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))

        guard magnitude1 > 0 && magnitude2 > 0 else {
            return 0
        }

        return dotProduct / (magnitude1 * magnitude2)
    }

    // MARK: - Private Helper Methods

    /// Simple tokenization (basic whitespace tokenization for MVP)
    /// In production, this should use the actual tokenizer from the model
    private func tokenize(text: String) throws -> (inputIds: [Int], attentionMask: [Int]) {
        // This is a simplified tokenizer for MVP
        // In production, you'd use the actual tokenizer.json file

        // Basic word tokenization
        let tokens = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Simple mapping to token IDs (this is a placeholder)
        // Real implementation would use the tokenizer vocabulary
        var inputIds = [101] // [CLS] token

        for token in tokens.prefix(maxTokens - 2) {
            // Use hash of token as a simple token ID (not ideal, but works for MVP)
            let tokenId = abs(token.hashValue % 30000) + 1000
            inputIds.append(tokenId)
        }

        inputIds.append(102) // [SEP] token

        // Create attention mask (1 for real tokens, 0 for padding)
        var attentionMask = Array(repeating: 1, count: inputIds.count)

        // Pad to max length
        while inputIds.count < maxTokens {
            inputIds.append(0) // PAD token
            attentionMask.append(0)
        }

        return (inputIds: inputIds, attentionMask: attentionMask)
    }

    /// Create MLMultiArray from array of integers
    private func createMLMultiArray(from array: [Int]) throws -> MLMultiArray {
        let multiArray = try MLMultiArray(shape: [1, NSNumber(value: maxTokens)], dataType: .int32)

        for (index, value) in array.enumerated() {
            multiArray[index] = NSNumber(value: value)
        }

        return multiArray
    }

    /// Extract embedding vector from MLMultiArray output
    private func extractEmbedding(from multiArray: MLMultiArray) throws -> [Float] {
        // The output shape should be [1, sequence_length, embedding_dim]
        // We want the [CLS] token embedding at position 0

        var embedding: [Float] = []
        let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

        // Extract the first token's embedding (CLS token)
        for i in 0..<embeddingDimension {
            embedding.append(pointer[i])
        }

        return embedding
    }
}

// MARK: - Error Types

public enum EmbeddingError: LocalizedError {
    case modelNotFound(String)
    case initializationFailed(String)
    case modelNotReady
    case tokenizationFailed(String)
    case invalidOutput
    case invalidInputDimensions

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Embedding model not found at path: \(path)"
        case .initializationFailed(let reason):
            return "Failed to initialize embedding model: \(reason)"
        case .modelNotReady:
            return "Embedding model is not ready. Call initialize() first."
        case .tokenizationFailed(let reason):
            return "Failed to tokenize input text: \(reason)"
        case .invalidOutput:
            return "Model produced invalid output"
        case .invalidInputDimensions:
            return "Input dimensions don't match model requirements"
        }
    }
}
