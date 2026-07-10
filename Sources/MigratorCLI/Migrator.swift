import ArgumentParser
import MigratorCore

@main
struct Migrator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migrator",
        abstract: "Автоматизированная миграция iOS/macOS проектов с Swift 5 на Swift 6.",
        version: MigratorCore.version
        // Подкоманды analyze/report появятся в SWIFTMIG-9
    )
}
