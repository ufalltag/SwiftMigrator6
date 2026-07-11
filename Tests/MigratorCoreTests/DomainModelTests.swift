import Foundation
import Testing
@testable import MigratorCore

/// Тесты доменной модели: сериализация без потерь.
/// Round-trip покрывает всю иерархию: проект → модули → файлы
/// и предложение фикса → проблема → диагностика → локация.

private func makeSampleProject() -> AnalyzedProject {
    AnalyzedProject(
        path: "/tmp/DemoProject",
        buildSystem: .spm,
        modules: [
            Module(
                name: "AppCore",
                files: [SourceFile(path: "/tmp/DemoProject/Sources/AppCore/State.swift", moduleName: "AppCore")],
                dependencies: []
            ),
            Module(
                name: "AppUI",
                files: [SourceFile(path: "/tmp/DemoProject/Sources/AppUI/View.swift", moduleName: "AppUI")],
                dependencies: ["AppCore"]
            ),
        ]
    )
}

private func makeSampleProposal() -> FixProposal {
    let diagnostic = Diagnostic(
        code: "global_var_concurrency",
        message: "var 'shared' is not concurrency-safe because it is nonisolated global shared mutable state",
        severity: .error,
        location: SourceLocation(
            filePath: "/tmp/DemoProject/Sources/AppCore/State.swift",
            line: 3,
            column: 5
        )
    )
    let issue = MigrationIssue(
        diagnostic: diagnostic,
        category: .globalMutableState,
        route: .deterministic(FixRuleID(rawValue: "global-var-to-let"))
    )
    return FixProposal(
        issue: issue,
        patch: """
        --- a/Sources/AppCore/State.swift
        +++ b/Sources/AppCore/State.swift
        @@ -3 +3 @@
        -var shared = Config()
        +let shared = Config()
        """
    )
}

@Test func analyzedProjectCodableRoundTrip() throws {
    // given
    let original = makeSampleProject()

    // when
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnalyzedProject.self, from: data)

    // then
    #expect(decoded == original)
}

@Test func fixProposalCodableRoundTrip() throws {
    // given
    let original = makeSampleProposal()

    // when
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(FixProposal.self, from: data)

    // then
    #expect(decoded == original)
    #expect(decoded.status == .proposed)
}

@Test func migrationRouteEncodesAssociatedValue() throws {
    // given
    let route = MigrationRoute.deterministic(FixRuleID(rawValue: "global-var-to-let"))

    // when
    let data = try JSONEncoder().encode(route)
    let decoded = try JSONDecoder().decode(MigrationRoute.self, from: data)

    // then
    #expect(decoded == route)
}
