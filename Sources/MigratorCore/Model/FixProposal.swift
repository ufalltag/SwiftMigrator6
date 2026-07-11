import Foundation

/// Предложенное исправление проблемы миграции
public struct FixProposal: Sendable, Equatable, Codable, Identifiable {
    
    public var id: UUID
    
    public var issue: MigrationIssue

    /// Изменение кода в формате unified diff — единый формат и для
    /// детерминированных фиксов, и для ответов LLM, и для превью в UI
    public var patch: String
    
    public var status: FixStatus
    
    public init(
        id: UUID = UUID(),
        issue: MigrationIssue,
        patch: String,
        status: FixStatus = .proposed
    ) {
        self.id = id
        self.issue = issue
        self.patch = patch
        self.status = status
    }
}

public enum FixStatus: String, Sendable, Equatable, Codable {
    /// Создано, ожидает решения (автоверификации или пользователя).
    case proposed
    
    /// Применено к коду и прошло верификацию перекомпиляцией.
    case applied
    
    /// Отклонено пользователем или верификацией.
    case rejected
    
    /// Применение не удалось (патч не лёг, код не компилируется).
    case failed
}
