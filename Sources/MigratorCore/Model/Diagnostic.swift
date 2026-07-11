import Foundation

/// Диагностика компилятора, собранная при сборке со строгой конкурентностью
public struct Diagnostic: Sendable, Equatable, Codable {
    
    /// Код диагностики компилятора, если удалось извлечь
    /// Основной ключ для классификатора; `nil` — классификация только по тексту
    public var code: String?
    
    public var message: String
    
    public var severity: DiagnosticSeverity
    
    public var location: SourceLocation
    
    public init(
        code: String?,
        message: String,
        severity: DiagnosticSeverity,
        location: SourceLocation
    ) {
        self.code = code
        self.message = message
        self.severity = severity
        self.location = location
    }
}

/// Серьёзность диагностики компилятора
public enum DiagnosticSeverity: String, Sendable, Equatable, Codable {
    case error
    case warning
    case note
}

public struct SourceLocation: Sendable, Equatable, Codable {
    
    public var filePath: String
    
    public var line: Int
    
    public var column: Int
    
    public init(filePath: String, line: Int, column: Int) {
        self.filePath = filePath
        self.line = line
        self.column = column
    }
}
