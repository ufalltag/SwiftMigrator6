import Foundation

/// Результат анализа проекта пользователя: корневой объект доменной модели
public struct AnalyzedProject: Sendable, Equatable, Codable {
    
    public var path: String
    
    public var buildSystem: BuildSystem
    
    public var modules: [Module]

    public init(path: String, buildSystem: BuildSystem, modules: [Module]) {
        self.path = path
        self.buildSystem = buildSystem
        self.modules = modules
    }
}

public enum BuildSystem: String, Sendable, Equatable, Codable {
    case spm
    case xcodeproj
}

public struct Module: Sendable, Equatable, Codable {
    
    public var name: String
    
    public var files: [SourceFile]

    /// Имена модулей, от которых зависит данный (рёбра графа зависимостей).
    /// Ссылки по имени, а не по значению, чтобы модель оставалась деревом
    /// и сериализовалась без циклов
    public var dependencies: [String]

    public init(name: String, files: [SourceFile], dependencies: [String]) {
        self.name = name
        self.files = files
        self.dependencies = dependencies
    }
}

public struct SourceFile: Sendable, Equatable, Codable {
    
    public var path: String
    
    public var moduleName: String
    
    public init(path: String, moduleName: String) {
        self.path = path
        self.moduleName = moduleName
    }
}
