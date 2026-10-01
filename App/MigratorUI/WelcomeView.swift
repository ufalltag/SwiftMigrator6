import SwiftUI
import AppKit

/// Стартовый экран в духе welcome-окна Xcode: слева иконка, имя и
/// печатающийся слоган поверх живого графа, справа — недавние проекты.
/// Проект открывается через NSOpenPanel или перетаскиванием папки в окно.
struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 0) {
            heroPane
            Divider()
            RecentProjectsPane()
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            appState.openProject(at: url)
            return true
        } isTargeted: { isDropTargeted = $0 }
    }

    private var heroPane: some View {
        VStack(spacing: 10) {
            Spacer()

            Image(systemName: "swift")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("SwiftMigrator6")
                .font(.system(size: 34, weight: .bold))

            Text("Версия \(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            TypewriterText(text: "Анализ, диагностика и миграция кода на Swift 6")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
                .padding(.top, 4)

            OpenProjectButton(isDropTargeted: isDropTargeted) {
                chooseProjectFolder()
            }
            .padding(.top, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                GraphBackgroundView()
                    .opacity(isDropTargeted ? 1.0 : 0.6)
                // Виньетка под контентом, чтобы текст читался поверх графа
                RadialGradient(
                    colors: [Color(nsColor: .windowBackgroundColor).opacity(0.9), .clear],
                    center: .center,
                    startRadius: 40,
                    endRadius: 280
                )
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func chooseProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Выберите папку проекта (с Package.swift или .xcodeproj)"
        panel.prompt = "Открыть"
        if panel.runModal() == .OK, let url = panel.url {
            appState.openProject(at: url)
        }
    }
}

/// Карточка-дропзона «Открыть проект»: кнопка и цель перетаскивания в одном
/// контроле. Пунктирная рамка — знакомая метафора зоны сброса; подсвечивается
/// при наведении и когда над окном тащат папку.
private struct OpenProjectButton: View {
    let isDropTargeted: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var isHighlighted: Bool { isHovered || isDropTargeted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Открыть проект…")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("или перетащите папку сюда")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Text("⌘O")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.orange.opacity(isHighlighted ? 0.12 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        Color.orange.opacity(isHighlighted ? 0.7 : 0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .keyboardShortcut("o")
        .onHover { isHovered = $0 }
        .animation(.smooth(duration: 0.2), value: isHighlighted)
    }
}

/// Мгновенный отклик на нажатие: лёгкое сжатие, как у нативных контролов
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Без недавних") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.recentProjectPaths = []
    return WelcomeView()
        .environment(state)
        .frame(width: 680, height: 420)
}

#Preview("С недавними") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.recentProjectPaths = [
        NSHomeDirectory() + "/Projects/SamplePackage",
        NSHomeDirectory() + "/Work/MigratorPlayground",
        NSHomeDirectory() + "/Developer/DemoProject",
    ]
    return WelcomeView()
        .environment(state)
        .frame(width: 680, height: 420)
}
