import Foundation
@testable import MigratorCore

struct MockFixRule: FixRule {
    
    var id = FixRuleID(rawValue: "mock-rule")
    var fixableCategories: Set<IssueCategory> = [.globalMutableState]
    var stubbedPatch = "--- a/mock\n+++ b/mock\n"

    func canFix(_ issue: MigrationIssue) -> Bool {
        fixableCategories.contains(issue.category)
    }

    func makeFix(for issue: MigrationIssue, fileContents: String) throws -> FixProposal? {
        guard canFix(issue) else { return nil }
        return FixProposal(issue: issue, patch: stubbedPatch)
    }
}
