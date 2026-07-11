import ArgumentParser
import MigratorCore

@main
struct Migrator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migrator",
        abstract: "Автоматизированная миграция iOS/macOS проектов с Swift 5 на Swift 6.",
        discussion: "Коды возврата: 0 — успех, 1 — ошибка анализа, 2 — невалидный вход.",
        version: MigratorCore.version,
        subcommands: [Analyze.self, Report.self]
    )
}
