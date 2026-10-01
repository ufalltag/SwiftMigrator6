import SwiftUI

@main
struct MigratorUIApp: App {
    /// Точка DI: пока настоящих реализаций нет, приложение живёт на мок-лоадере.
    @State private var appState = AppState(projectLoader: MockProjectLoader())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
