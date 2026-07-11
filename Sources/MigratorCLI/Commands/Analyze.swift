import ArgumentParser
import Foundation
import MigratorCore

struct Analyze: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "Проанализировать структуру проекта: модули и файлы."
    )
    
    @Argument(help: "Путь к корню проекта (папка с Package.swift).")
    var path: String
    
    @Flag(help: "Вывести результат в машиночитаемом JSON.")
    var json = false
    
    func run() async throws {
        let project = try await CLISupport.loadProject(at: path)

        if json {
            try CLISupport.printJSON(project)
        } else {
            printTree(for: project)
        }
    }
    
    /// Дерево модулей с зависимостями:
    /// ```
    /// ✓ found 2 modules · spm
    ///   ├─ DemoCore  1 file(s)
    ///   └─ DemoUI  2 file(s) ─▶ DemoCore
    /// ```
    private func printTree(for project: AnalyzedProject) {
        let check = ConsoleStyle.green("✓")
        let badge = ConsoleStyle.dim("· \(project.buildSystem.rawValue)")
        print("\(check) found \(project.modules.count) modules \(badge)")

        for (index, module) in project.modules.enumerated() {
            let connector = index == project.modules.count - 1 ? "└─" : "├─"
            var line = "  \(ConsoleStyle.dim(connector)) \(ConsoleStyle.bold(module.name))"
            line += "  \(ConsoleStyle.dim("\(module.files.count) file(s)"))"
            if !module.dependencies.isEmpty {
                let deps = module.dependencies.joined(separator: ", ")
                line += " \(ConsoleStyle.dim("─▶")) \(ConsoleStyle.cyan(deps))"
            }
            print(line)
        }
    }
}
