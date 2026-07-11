import Foundation
@testable import MigratorCore

struct MockDiagnosticsProvider: DiagnosticsProvider {
    
    var stubbedDiagnostics: [String: [Diagnostic]]
    
    func diagnostics(for module: Module, in project: AnalyzedProject) async throws -> [Diagnostic] {
        stubbedDiagnostics[module.name] ?? []
    }
}
