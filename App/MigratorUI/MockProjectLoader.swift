import Foundation
import MigratorCore

/// Мок-лоадер для скелета UI и превью: возвращает фиксированный проект
/// с небольшой задержкой, чтобы был виден экран загрузки.
struct MockProjectLoader: ProjectLoader {

    func load(projectAt path: String) async throws -> AnalyzedProject {
        try await Task.sleep(for: .milliseconds(400))
        var project = AnalyzedProject.mock
        project.path = path
        return project
    }
}

extension AnalyzedProject {

    static let mock = AnalyzedProject(
        path: "/Users/demo/Projects/SamplePackage",
        buildSystem: .spm,
        modules: [
            Module(
                name: "SampleApp",
                files: [
                    SourceFile(path: "Sources/SampleApp/App.swift", moduleName: "SampleApp"),
                    SourceFile(path: "Sources/SampleApp/RootView.swift", moduleName: "SampleApp"),
                ],
                dependencies: ["SampleCore", "SampleUI"]
            ),
            Module(
                name: "SampleCore",
                files: [
                    SourceFile(path: "Sources/SampleCore/Engine.swift", moduleName: "SampleCore"),
                ],
                dependencies: []
            ),
            Module(
                name: "SampleUI",
                files: [
                    SourceFile(path: "Sources/SampleUI/Components.swift", moduleName: "SampleUI"),
                    SourceFile(path: "Sources/SampleUI/Theme.swift", moduleName: "SampleUI"),
                    SourceFile(path: "Sources/SampleUI/Icons.swift", moduleName: "SampleUI"),
                ],
                dependencies: ["SampleCore"]
            ),
        ]
    )
}
