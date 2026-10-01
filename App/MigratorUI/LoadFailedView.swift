import SwiftUI

struct LoadFailedView: View {
    @Environment(AppState.self) private var appState

    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Не удалось загрузить проект", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Выбрать другую папку") {
                appState.reset()
            }
        }
    }
}

#Preview {
    LoadFailedView(message: "Папка не содержит Package.swift или .xcodeproj")
        .environment(AppState(projectLoader: MockProjectLoader()))
        .frame(width: 520, height: 360)
}
