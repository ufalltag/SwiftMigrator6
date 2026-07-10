import Testing
@testable import MigratorCore

@Test func coreVersionIsNotEmpty() {
    #expect(!MigratorCore.version.isEmpty)
}
