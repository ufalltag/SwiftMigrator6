import ArgumentParser
import Foundation
import MigratorCore

/// `migrator report <path> --format json|md` — dry-run отчёт о миграции.
/// Пока заглушка: реальные диагностики и категории появятся после этапов 1–2.
struct Report: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Сформировать отчёт о миграции без внесения изменений (заглушка)."
    )

    enum Format: String, ExpressibleByArgument, CaseIterable {
        case json
        case md
    }

    @Argument(help: "Путь к корню проекта (папка с Package.swift).")
    var path: String

    @Option(help: "Формат отчёта: \(Format.allCases.map(\.rawValue).joined(separator: " | ")).")
    var format: Format = .md

    func run() async throws {
        let project = try await CLISupport.loadProject(at: path)

        switch format {
        case .md:
            print("# Отчёт о миграции (заглушка)")
            print("")
            print("- Проект: \(project.path)")
            print("- Модулей: \(project.modules.count)")
            print("")
            print("Диагностики, категории и маршруты появятся после этапов 1–2.")
        case .json:
            struct StubReport: Encodable {
                var project: AnalyzedProject
                var note: String
            }
            try CLISupport.printJSON(StubReport(
                project: project,
                note: "stub: diagnostics and issues arrive with stages 1-2"
            ))
        }
    }
}
