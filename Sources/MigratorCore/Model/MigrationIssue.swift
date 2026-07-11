import Foundation

/// Проблема миграции: диагностика компилятора, обогащённая категорией и маршрутом исправления
public struct MigrationIssue: Sendable, Equatable, Codable, Identifiable {
    
    public var id: UUID
    
    public var diagnostic: Diagnostic
    
    public var category: IssueCategory
    
    public var route: MigrationRoute
    
    public init(
        id: UUID = UUID(),
        diagnostic: Diagnostic,
        category: IssueCategory,
        route: MigrationRoute
    ) {
        self.id = id
        self.diagnostic = diagnostic
        self.category = category
        self.route = route
    }
}

/// Категории проблем миграции — 4 категории из scope диплома + `unknown`.
///
/// - TODO: Дополнить после этапа 0 (анализ корпуса проектов): текущий набор —
///   гипотеза из типовых ошибок strict concurrency. По таблице «категория × частота»
///   из каталога ошибок корпуса добавить недостающие кейсы (кандидаты: захват
///   не-Sendable значений в `Task {}`, nonisolated протокольные требования,
///   делегаты с неизолированными колбэками). Существующие кейсы не переименовывать —
///   raw value уже участвует в сериализации.
public enum IssueCategory: String, Sendable, Equatable, Codable, CaseIterable {
    /// UI-тип (наследник UIView/UIViewController и т.п.) без изоляции на главном акторе.
    /// Типовой фикс: добавить `@MainActor`.
    case missingMainActor
    
    /// Тип пересекает границу изоляции, но не объявлен `Sendable`.
    /// Типовой фикс для immutable struct: добавить конформанс `Sendable`.
    case missingSendable
    
    /// Глобальная или статическая изменяемая переменная — общая мутабельная память.
    /// Типовой фикс: `var` → `let`, если запись не обнаружена.
    case globalMutableState
    
    /// Диагностика вызвана типами из модуля без аннотаций конкурентности.
    /// Типовой фикс: `@preconcurrency import`.
    case preconcurrencyImport
    
    /// Категория не распознана классификатором. Маршрут — только `manual`
    /// или `llmAssisted`; детерминированные фиксы не применяются.
    case unknown
}

/// Маршрут исправления проблемы
public enum MigrationRoute: Sendable, Equatable, Codable {
    /// Исправляется детерминированным правилом с указанным идентификатором
    case deterministic(FixRuleID)

    /// Требует понимания контекста — отправляется в LLM-слой
    case llmAssisted

    /// Автоматическое исправление невозможно или небезопасно вручную
    case manual
}

public struct FixRuleID: Sendable, Equatable, Hashable, Codable, RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
