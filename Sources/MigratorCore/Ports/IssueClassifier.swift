import Foundation

public protocol IssueClassifier: Sendable {
    /// Классифицирует диагностики в проблемы миграции с категорией и маршрутом
    func classify(_ diagnostics: [Diagnostic], in project: AnalyzedProject) async throws -> [MigrationIssue]
}
