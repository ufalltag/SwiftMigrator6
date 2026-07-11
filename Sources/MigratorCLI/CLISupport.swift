import ArgumentParser
import Foundation
import MigratorCore

/// Общие помощники команд: загрузка проекта с маппингом ошибок в коды возврата
/// (0 — успех, 1 — ошибка анализа, 2 — невалидный вход) и вывод в stderr.
enum CLISupport {

    static func loadProject(at path: String) async throws -> AnalyzedProject {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            printError("путь не существует или не является папкой: \(path)")
            throw ExitCode(2)
        }

        do {
            return try await StubProjectLoader().load(projectAt: path)
        } catch let failure as StubProjectLoader.Failure {
            switch failure {
            case .notAProject(let projectPath):
                printError("не похоже на SPM-проект, нет Package.swift: \(projectPath)")
                throw ExitCode(2)
            case .unreadable(let sourcesPath):
                printError("не удалось прочитать структуру проекта: \(sourcesPath)")
                throw ExitCode(1)
            }
        }
    }

    static func printError(_ message: String) {
        let prefix = ConsoleStyle.red("error:", colored: ConsoleStyle.stderrColored)
        FileHandle.standardError.write(Data("\(prefix) \(message)\n".utf8))
    }

    static func printJSON(_ value: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        print(String(decoding: data, as: UTF8.self))
    }
}
