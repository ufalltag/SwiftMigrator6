import Foundation

public protocol LLMProvider: Sendable {
    /// Запрашивает у модели исправление проблемы
    func proposeFix(for request: LLMFixRequest) async throws -> LLMFixResponse
}

public struct LLMFixRequest: Sendable, Equatable, Codable {
    
    public var issue: MigrationIssue
    
    public var contextSnippets: [String]
    
    public init(issue: MigrationIssue, contextSnippets: [String]) {
        self.issue = issue
        self.contextSnippets = contextSnippets
    }
}

public struct LLMFixResponse: Sendable, Equatable, Codable {
    
    public var patch: String?
    
    public var explanation: String
    
    public init(patch: String?, explanation: String) {
        self.patch = patch
        self.explanation = explanation
    }
}
