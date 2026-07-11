import Foundation

public protocol DiagnosticsProvider: Sendable {
    /// Собирает диагностики строгой конкурентности для одного модуля.
    func diagnostics(for module: Module, in project: AnalyzedProject) async throws -> [Diagnostic]
    
    /// Собирает диагностики для всего проекта.
    func diagnostics(for project: AnalyzedProject) async throws -> [Diagnostic]
}

extension DiagnosticsProvider {

    public func diagnostics(for project: AnalyzedProject) async throws -> [Diagnostic] {
        var result: [Diagnostic] = []
        for module in project.modules {
            result += try await diagnostics(for: module, in: project)
        }
        return result
    }
}
