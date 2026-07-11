import Foundation

public protocol FixRule: Sendable {

    var id: FixRuleID { get }

    /// Быстрая проверка применимости по данным проблемы (без чтения исходников)
    func canFix(_ issue: MigrationIssue) -> Bool

    /// Строит исправление для проблемы по содержимому исходного файла
    /// - Returns: предложение с патчем или `nil`, если правило «не уверено»
    func makeFix(for issue: MigrationIssue, fileContents: String) throws -> FixProposal?
}
