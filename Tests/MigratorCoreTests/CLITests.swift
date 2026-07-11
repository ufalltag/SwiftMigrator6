import Foundation
import Testing

/// Тесты CLI: запускают собранный бинарь `migrator` как отдельный процесс
/// и проверяют вывод и коды возврата (0 — успех, 1 — ошибка анализа, 2 — невалидный вход).

private let fixturePath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // MigratorCoreTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // корень репозитория
    .appendingPathComponent("Fixtures/DemoProject")
    .path

/// Бинарь migrator лежит рядом с бандлом тестовых ресурсов при запуске через
/// `swift test` (SPM собирает все продукты пакета). Xcode/xcodebuild собирает
/// только зависимости тестов — бинаря нет, и такие тесты помечаются skipped.
let migratorBinary = Bundle.module.bundleURL
    .deletingLastPathComponent()
    .appendingPathComponent("migrator")

let migratorBinaryExists = FileManager.default.fileExists(atPath: migratorBinary.path)

private func runMigrator(_ arguments: [String]) throws -> (status: Int32, output: String) {
    let binary = migratorBinary

    let process = Process()
    process.executableURL = binary
    process.arguments = arguments
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr
    try process.run()
    process.waitUntilExit()

    let output = String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return (process.terminationStatus, output)
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func analyzeFindsModulesInFixture() throws {
    // given: фикстура DemoProject с модулями DemoCore и DemoUI

    // when
    let result = try runMigrator(["analyze", fixturePath])

    // then
    #expect(result.status == 0)
    #expect(result.output.contains("found 2 modules"))
    #expect(result.output.contains("DemoCore"))
    #expect(result.output.contains("DemoUI"))
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func analyzeJSONIsMachineReadable() throws {
    // given: фикстура DemoProject

    // when
    let result = try runMigrator(["analyze", fixturePath, "--json"])
    let object = try JSONSerialization.jsonObject(with: Data(result.output.utf8)) as? [String: Any]

    // then
    #expect(result.status == 0)
    let modules = object?["modules"] as? [[String: Any]]
    #expect(modules?.count == 2)
    let demoUI = modules?.first { ($0["name"] as? String) == "DemoUI" }
    #expect(demoUI?["dependencies"] as? [String] == ["DemoCore"])
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func analyzePipedOutputHasNoANSICodes() throws {
    // given: вывод в pipe (не TTY) — раскраска должна отключиться сама

    // when
    let result = try runMigrator(["analyze", fixturePath])

    // then
    #expect(!result.output.contains("\u{1B}["))
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func analyzeNonexistentPathExitsWithCode2() throws {
    // given
    let missingPath = "/nonexistent/path"

    // when
    let result = try runMigrator(["analyze", missingPath])

    // then
    #expect(result.status == 2)
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func analyzeFolderWithoutPackageSwiftExitsWithCode2() throws {
    // given: папка существует, но SPM-проектом не является
    let notAProject = FileManager.default.temporaryDirectory.path

    // when
    let result = try runMigrator(["analyze", notAProject])

    // then
    #expect(result.status == 2)
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func reportStubPrintsMarkdown() throws {
    // given: фикстура DemoProject

    // when
    let result = try runMigrator(["report", fixturePath, "--format", "md"])

    // then
    #expect(result.status == 0)
    #expect(result.output.contains("# Отчёт о миграции"))
    #expect(result.output.contains("Модулей: 2"))
}

@Test(.enabled(if: migratorBinaryExists, "нужен бинарь migrator — есть только под swift test")) func helpDescribesAllCommands() throws {
    // given: собранный бинарь migrator

    // when
    let result = try runMigrator(["--help"])

    // then
    #expect(result.status == 0)
    #expect(result.output.contains("analyze"))
    #expect(result.output.contains("report"))
}
