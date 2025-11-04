// MARK: - Environment Values
private struct ThemeManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = ThemeManager.shared
}
