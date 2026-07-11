import Foundation
import SwiftParser
import SwiftSyntax
import Testing
import XcodeProj

/// Smoke-тесты зависимостей проверяют, что зафиксированные версии
/// swift-syntax, XcodeProj и swift-argument-parser реально работают в нашей сборке.

@Test func swiftSyntaxParsesSourceIntoSourceFileSyntax() {
    // given
    let source = "let answer = 42"

    // when
    let tree: SourceFileSyntax = Parser.parse(source: source)

    // then
    #expect(!tree.hasError)
    #expect(tree.description == source)
}

@Test func xcodeProjOpensEmptyProjectFixture() throws {
    // given
    let url = try #require(
        Bundle.module.url(
            forResource: "Empty",
            withExtension: "xcodeproj",
            subdirectory: "Fixtures"
        )
    )

    // when
    let project = try XcodeProj(pathString: url.path)

    // then
    #expect(project.pbxproj.rootObject != nil)
    #expect(project.pbxproj.nativeTargets.isEmpty)
}

@Test func cliPrintsHelp() throws {
    // given
    let binary = Bundle.module.bundleURL
        .deletingLastPathComponent()
        .appendingPathComponent("migrator")
    let process = Process()
    process.executableURL = binary
    process.arguments = ["--help"]
    let pipe = Pipe()
    process.standardOutput = pipe

    // when
    try process.run()
    process.waitUntilExit()
    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

    // then
    #expect(process.terminationStatus == 0)
    #expect(output.contains("USAGE"))
    #expect(output.contains("migrator"))
}
