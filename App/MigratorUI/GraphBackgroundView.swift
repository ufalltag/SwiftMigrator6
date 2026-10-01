import SwiftUI

/// Живой фон стартового экрана: узлы графа медленно дрейфуют, рёбра
/// возникают между сблизившимися узлами и тают при отдалении — форма
/// графа непрерывно меняется. При reduced motion рисуется статичный кадр.
struct GraphBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let points = Self.nodes.map { $0.position(at: t, in: size) }

                // Рёбра: чем ближе узлы, тем плотнее линия
                let threshold = min(size.width, size.height) * 0.34
                for i in points.indices {
                    for j in (i + 1)..<points.count {
                        let distance = hypot(points[i].x - points[j].x,
                                             points[i].y - points[j].y)
                        guard distance < threshold else { continue }
                        let strength = 1 - distance / threshold
                        var edge = Path()
                        edge.move(to: points[i])
                        edge.addLine(to: points[j])
                        context.stroke(
                            edge,
                            with: .color(.secondary.opacity(0.45 * strength)),
                            lineWidth: 1
                        )
                    }
                }

                // Узлы: лёгкое «дыхание» радиуса
                for (node, point) in zip(Self.nodes, points) {
                    let radius = node.radius + CGFloat(sin(t * node.pulseSpeed + node.phase)) * 0.8
                    let rect = CGRect(x: point.x - radius, y: point.y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.orange.opacity(node.brightness))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static let nodes: [GraphNode] = GraphNode.make(count: 22, seed: 0xC0FFEE)
}

/// Узел фонового графа: траектория — функция времени (Лиссажу-подобный
/// дрейф вокруг якоря), поэтому анимация не хранит состояние между кадрами.
private struct GraphNode {
    /// Якорь и размах дрейфа — в долях размера окна
    var anchor: CGPoint
    var amplitude: CGSize
    var speed: (x: Double, y: Double)
    var phase: Double
    var radius: CGFloat
    var pulseSpeed: Double
    var brightness: Double

    func position(at t: TimeInterval, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (anchor.x + amplitude.width * sin(t * speed.x + phase)) * size.width,
            y: (anchor.y + amplitude.height * cos(t * speed.y + phase * 1.7)) * size.height
        )
    }

    static func make(count: Int, seed: UInt64) -> [GraphNode] {
        var rng = SplitMix64(seed: seed)
        return (0..<count).map { _ in
            GraphNode(
                anchor: CGPoint(x: CGFloat.random(in: 0.05...0.95, using: &rng),
                                y: CGFloat.random(in: 0.05...0.95, using: &rng)),
                amplitude: CGSize(width: CGFloat.random(in: 0.04...0.11, using: &rng),
                                  height: CGFloat.random(in: 0.04...0.11, using: &rng)),
                speed: (Double.random(in: 0.05...0.22, using: &rng),
                        Double.random(in: 0.05...0.22, using: &rng)),
                phase: .random(in: 0...(2 * .pi), using: &rng),
                radius: .random(in: 2.5...5.5, using: &rng),
                pulseSpeed: .random(in: 0.4...0.9, using: &rng),
                brightness: .random(in: 0.35...0.8, using: &rng)
            )
        }
    }
}

/// Детерминированный RNG: один и тот же граф при каждом запуске и в превью
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#Preview {
    GraphBackgroundView()
        .frame(width: 520, height: 360)
}
