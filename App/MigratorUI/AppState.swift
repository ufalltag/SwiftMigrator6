import Foundation
import Observation
import MigratorCore

/// Корневая модель приложения: единственный источник правды для UI.
/// Core-сервисы приходят через init портами — в превью и тестах подставляются моки.
@MainActor
@Observable
final class AppState {

    enum Phase: Equatable {
        case idle
        case loading
        case loaded(AnalyzedProject)
        case failed(message: String)
    }

    var phase: Phase = .idle

    /// Пути недавно открытых проектов, новые в начале; переживают перезапуск
    var recentProjectPaths: [String]

    private let projectLoader: any ProjectLoader

    private static let recentsKey = "recentProjectPaths"
    private static let recentsLimit = 8

    init(projectLoader: any ProjectLoader) {
        self.projectLoader = projectLoader
        self.recentProjectPaths = UserDefaults.standard.stringArray(forKey: Self.recentsKey) ?? []
    }

    func openProject(at url: URL) {
        phase = .loading
        Task {
            do {
                let project = try await projectLoader.load(projectAt: url.path)
                addRecent(url.path)
                phase = .loaded(project)
            } catch {
                phase = .failed(message: error.localizedDescription)
            }
        }
    }

    private func addRecent(_ path: String) {
        recentProjectPaths.removeAll { $0 == path }
        recentProjectPaths.insert(path, at: 0)
        recentProjectPaths = Array(recentProjectPaths.prefix(Self.recentsLimit))
        UserDefaults.standard.set(recentProjectPaths, forKey: Self.recentsKey)
    }

    func reset() {
        phase = .idle
    }
}
