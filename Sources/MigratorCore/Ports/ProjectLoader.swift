import Foundation

public protocol ProjectLoader: Sendable {
    /// Анализирует проект по пути к его корню (папка с Package.swift или .xcodeproj)
    func load(projectAt path: String) async throws -> AnalyzedProject
}
