import SwiftUI
import MigratorCore

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.phase {
            case .idle:
                WelcomeView()
            case .loading:
                ProgressView("Анализ проекта…")
            case .loaded(let project):
                ProjectSummaryView(project: project)
            case .failed(let message):
                LoadFailedView(message: message)
            }
        }
        .frame(minWidth: 680, minHeight: 420)
        // Кроссфейд между фазами: симметричный вход/выход, безопасен при reduced motion
        .animation(.smooth(duration: 0.25), value: appState.phase)
    }
}

#Preview("Старт") {
    ContentView()
        .environment(AppState(projectLoader: MockProjectLoader()))
}

#Preview("Загружен") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.phase = .loaded(.mock)
    return ContentView().environment(state)
}

#Preview("Ошибка") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.phase = .failed(message: "Папка не содержит Package.swift или .xcodeproj")
    return ContentView().environment(state)
}
