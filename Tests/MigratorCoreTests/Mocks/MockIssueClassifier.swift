import Foundation
@testable import MigratorCore

struct MockIssueClassifier: IssueClassifier {
    
    var stubbedCategory: IssueCategory = .unknown
    var stubbedRoute: MigrationRoute = .manual
    
    func classify(_ diagnostics: [Diagnostic], in project: AnalyzedProject) async throws -> [MigrationIssue] {
        diagnostics.map {
            MigrationIssue(diagnostic: $0, category: stubbedCategory, route: stubbedRoute)
        }
    }
}
