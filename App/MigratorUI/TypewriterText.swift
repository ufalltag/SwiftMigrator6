import SwiftUI

/// Текст, печатающийся посимвольно с курсором — как ответ LLM в чате.
/// Скрытый полный текст резервирует место, чтобы вёрстка не прыгала.
/// При reduced motion показывается сразу целиком.
struct TypewriterText: View {
    let text: String
    var speed: Duration = .milliseconds(30)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCount = 0
    @State private var showsCursor = false

    var body: some View {
        Text(text)
            .hidden()
            .overlay(alignment: .top) {
                Text(String(text.prefix(visibleCount)))
                + Text(showsCursor ? "▌" : "")
                    .foregroundStyle(.orange)
            }
            .task { await type() }
    }

    private func type() async {
        guard !reduceMotion else {
            visibleCount = text.count
            return
        }
        showsCursor = true
        for index in 1...max(text.count, 1) {
            do { try await Task.sleep(for: speed) } catch { return }
            visibleCount = index
        }
        do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
        showsCursor = false
    }
}

#Preview {
    TypewriterText(text: "Анализ, диагностика и миграция кода на Swift 6")
        .padding()
}
