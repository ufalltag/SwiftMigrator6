import Foundation
import Testing
@testable import MigratorCore

private let sampleDiagnostic = Diagnostic(
    code: "global_var_concurrency",
    message: "var 'shared' is not concurrency-safe",
    severity: .error,
    location: SourceLocation(filePath: "/demo/Sources/App/State.swift", line: 3, column: 5)
)

private let sampleProject = AnalyzedProject(
    path: "/demo",
    buildSystem: .spm,
    modules: [
        Module(
            name: "App",
            files: [SourceFile(path: "/demo/Sources/App/State.swift", moduleName: "App")],
            dependencies: []
        )
    ]
)

@Test func pipelineRunsOnMocksOnly() async throws {
    // given
    let loader = MockProjectLoader(stubbedProject: sampleProject)
    let provider = MockDiagnosticsProvider(stubbedDiagnostics: ["App": [sampleDiagnostic]])
    let classifier = MockIssueClassifier(
        stubbedCategory: .globalMutableState,
        stubbedRoute: .deterministic(FixRuleID(rawValue: "mock-rule"))
    )
    let rule = MockFixRule()

    // when
    let project = try await loader.load(projectAt: "/demo")
    let diagnostics = try await provider.diagnostics(for: project)
    let issues = try await classifier.classify(diagnostics, in: project)
    let proposal = try #require(try rule.makeFix(for: issues[0], fileContents: "var shared = 0"))

    // then
    #expect(diagnostics.count == 1)
    #expect(issues[0].category == .globalMutableState)
    #expect(proposal.status == .proposed)
    #expect(proposal.issue.id == issues[0].id)
}

@Test func diagnosticsProviderDefaultImplementationConcatenatesModules() async throws {
    // given
    var project = sampleProject
    project.modules.append(Module(name: "Lib", files: [], dependencies: []))
    let provider = MockDiagnosticsProvider(
        stubbedDiagnostics: ["App": [sampleDiagnostic], "Lib": [sampleDiagnostic]]
    )

    // when
    let all = try await provider.diagnostics(for: project)

    // then
    #expect(all.count == 2)
}

@Test func fixRuleSaysNotSureWithNil() throws {
    // given
    let rule = MockFixRule(fixableCategories: [.globalMutableState])
    let unknownIssue = MigrationIssue(
        diagnostic: sampleDiagnostic,
        category: .unknown,
        route: .manual
    )

    // when
    let canFix = rule.canFix(unknownIssue)
    let fix = try rule.makeFix(for: unknownIssue, fileContents: "")

    // then
    #expect(!canFix)
    #expect(fix == nil)
}

@Test func llmProviderReturnsStructuredResponse() async throws {
    // given
    let llm = MockLLMProvider(
        stubbedResponse: LLMFixResponse(patch: "--- a\n+++ b\n", explanation: "add let")
    )
    let issue = MigrationIssue(diagnostic: sampleDiagnostic, category: .missingSendable, route: .llmAssisted)

    // when
    let response = try await llm.proposeFix(
        for: LLMFixRequest(issue: issue, contextSnippets: ["struct Config {}"])
    )

    // then
    #expect(response.patch != nil)
    #expect(!response.explanation.isEmpty)
}
