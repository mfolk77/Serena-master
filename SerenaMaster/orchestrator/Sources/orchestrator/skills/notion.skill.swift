extension NotionSkill {
    func call(_ input: String) async throws -> String {
        return "NotionSkill stubbed call for: \(input)"
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    func getStringOrNil(forKey key: String) -> String? { return nil }
}

class NotionSkill: Skill, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var apiKey: String = ""
    func call(_ input: String) async throws -> String {
        return "NotionSkill stubbed call for: \(input)"
    }
} 