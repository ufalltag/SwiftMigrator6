import Foundation
import MigratorCore

struct StubProjectLoader: ProjectLoader {

    enum Failure: Error {
        /// Нет Package.swift — вход невалиден (код возврата 2).
        case notAProject(String)
        /// Структура проекта не читается — ошибка анализа (код возврата 1).
        case unreadable(String)
    }

    func load(projectAt path: String) async throws -> AnalyzedProject {
        let root = URL(fileURLWithPath: path)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: root.appendingPathComponent("Package.swift").path) else {
            throw Failure.notAProject(path)
        }

        let sourcesDir = root.appendingPathComponent("Sources")
        guard let moduleDirs = try? fileManager.contentsOfDirectory(
            at: sourcesDir,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            throw Failure.unreadable(sourcesDir.path)
        }

        let sortedDirs = moduleDirs
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let moduleNames = Set(sortedDirs.map(\.lastPathComponent))

        let modules = sortedDirs.map { dir in
            let name = dir.lastPathComponent
            let fileURLs = ((try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.pathExtension == "swift" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            let swiftFiles = fileURLs.map { SourceFile(path: $0.path, moduleName: name) }
            let dependencies = importedModules(in: fileURLs)
                .intersection(moduleNames)
                .subtracting([name])
                .sorted()
            return Module(name: name, files: swiftFiles, dependencies: dependencies)
        }

        return AnalyzedProject(path: root.path, buildSystem: .spm, modules: modules)
    }

    /// Наивный сбор зависимостей: строки `import X` во всех файлах модуля.
    /// Для заглушки достаточно; полноценный анализ — этап 1 плана.
    private func importedModules(in fileURLs: [URL]) -> Set<String> {
        var imported: Set<String> = []
        for url in fileURLs {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("import ") else { continue }
                let name = trimmed.dropFirst("import ".count)
                    .split(separator: " ").last.map(String.init) ?? ""
                if !name.isEmpty { imported.insert(name) }
            }
        }
        return imported
    }
}
