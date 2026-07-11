import Foundation
@testable import MigratorCore

struct MockProjectLoader: ProjectLoader {
    
    var stubbedProject: AnalyzedProject
    
    func load(projectAt path: String) async throws -> AnalyzedProject {
        var project = stubbedProject
        project.path = path
        return project
    }
}
