import SwiftUI

/// Правая панель welcome-окна: недавние проекты, как в Xcode.
/// Клик по строке открывает проект заново.
struct RecentProjectsPane: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.recentProjectPaths.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(appState.recentProjectPaths, id: \.self) { path in
                            RecentProjectRow(path: path) {
                                appState.openProject(at: URL(fileURLWithPath: path))
                            }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(width: 280)
        .background(Color.primary.opacity(0.03))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ProjectIcon(size: 56, dimmed: true)
            VStack(spacing: 4) {
                Text("Нет недавних проектов")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Открытые проекты появятся здесь")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Иконка проекта в скруглённом контейнере — как мини-иконка приложения
private struct ProjectIcon: View {
    var size: CGFloat = 36
    var dimmed = false

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(
                dimmed
                    ? AnyShapeStyle(Color.primary.opacity(0.06))
                    : AnyShapeStyle(LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "folder.fill")
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(dimmed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.white))
            }
    }
}

private struct RecentProjectRow: View {
    let path: String
    let open: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                ProjectIcon()
                VStack(alignment: .leading, spacing: 2) {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.body.weight(.medium))
                    Text(abbreviatedPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.smooth(duration: 0.15), value: isHovered)
    }

    /// Домашняя папка сокращается до `~`, как в Finder и Xcode
    private var abbreviatedPath: String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }
}

#Preview("С проектами") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.recentProjectPaths = [
        NSHomeDirectory() + "/Projects/SamplePackage",
        NSHomeDirectory() + "/Work/LongProjectName/Deeply/Nested/MigratorPlayground",
    ]
    return RecentProjectsPane()
        .environment(state)
        .frame(height: 400)
}

#Preview("Пусто") {
    let state = AppState(projectLoader: MockProjectLoader())
    state.recentProjectPaths = []
    return RecentProjectsPane()
        .environment(state)
        .frame(height: 400)
}
