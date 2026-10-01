import SwiftUI
import MigratorCore

/// Экран-заглушка результата анализа: заголовок «Проект загружен: N модулей»
/// и список модулей от лоадера.
struct ProjectSummaryView: View {
    @Environment(AppState.self) private var appState

    let project: AnalyzedProject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Проект загружен: \(project.modules.count) \(plural(project.modules.count, "модуль", "модуля", "модулей"))")
                        .font(.title2.weight(.semibold))
                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                }
                Spacer()
                Button("Другой проект…") {
                    appState.reset()
                }
            }
            .padding()

            List(project.modules, id: \.name) { module in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.name)
                            .font(.headline)
                        Text(module.dependencies.isEmpty
                             ? "без зависимостей"
                             : "зависит от: \(module.dependencies.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(module.files.count) \(plural(module.files.count, "файл", "файла", "файлов"))")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

/// Русская плюрализация: 1 модуль, 2 модуля, 5 модулей.
func plural(_ count: Int, _ one: String, _ few: String, _ many: String) -> String {
    let mod100 = count % 100
    if (11...14).contains(mod100) { return many }
    switch count % 10 {
    case 1: return one
    case 2...4: return few
    default: return many
    }
}

#Preview {
    ProjectSummaryView(project: .mock)
        .environment(AppState(projectLoader: MockProjectLoader()))
        .frame(width: 520, height: 360)
}
