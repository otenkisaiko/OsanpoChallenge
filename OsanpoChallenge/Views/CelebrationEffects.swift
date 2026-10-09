import SwiftUI

/// 紙吹雪と桜の花びら。start の時刻から吹き上がって、ひらひら舞い落ちる
struct ConfettiView: View {
    /// 吹き出し口（画面に対する割合）と、打ち出す時刻のずれ（秒）
    struct Burst {
        var origin: UnitPoint
        /// 打ち出す向き（ラジアン。-π/2 が真上）
        var direction: Double = -.pi / 2
        /// 広がりの角度（ラジアン）
        var spread: Double = .pi * 0.9
        var count: Int
        var delay: Double = 0
    }

    let start: Date
    let bursts: [Burst]

    @State private var particles: [Particle] = []

    /// 1 枚が見えている時間（秒）
    private let lifetime: Double = 5

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start)
                Canvas { context, size in
                    for particle in particles {
                        draw(particle, at: elapsed - particle.delay, in: size, context: context)
                    }
                }
            }
            .onAppear {
                particles = bursts.flatMap { burst in
                    (0..<burst.count).map { _ in Particle.random(for: burst) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ p: Particle, at t: Double, in size: CGSize, context: GraphicsContext) {
        guard t > 0, t < lifetime else { return }
        // 空気抵抗のある放物線（だんだんゆっくり落ちる）
        let drag = 1.6, gravity = 320.0
        let decay = (1 - exp(-drag * t)) / drag
        let x = p.origin.x * size.width + p.velocity.dx * decay + p.sway * sin(p.swaySpeed * t + p.phase)
        let y = p.origin.y * size.height + (p.velocity.dy + gravity / drag) * decay - gravity / drag * t

        var c = context
        c.opacity = t > lifetime - 1 ? lifetime - t : 1
        c.translateBy(x: x, y: y)
        c.rotate(by: .radians(p.phase + p.spin * t))
        // くるくる裏返る動き
        c.scaleBy(x: cos(p.flip * t + p.phase), y: 1)

        let w = p.size, h = p.size
        switch p.shape {
        case .petal:
            var petal = Path()
            petal.move(to: CGPoint(x: 0, y: -h * 0.55))
            petal.addQuadCurve(to: CGPoint(x: 0, y: h * 0.55), control: CGPoint(x: w * 0.75, y: 0))
            petal.addQuadCurve(to: CGPoint(x: 0, y: -h * 0.55), control: CGPoint(x: -w * 0.75, y: 0))
            c.fill(petal, with: .color(p.color))
        case .paper:
            c.fill(Path(CGRect(x: -w / 2, y: -h * 0.22, width: w, height: h * 0.44)), with: .color(p.color))
        case .dot:
            c.fill(Path(ellipseIn: CGRect(x: -w * 0.3, y: -w * 0.3, width: w * 0.6, height: w * 0.6)),
                   with: .color(p.color))
        }
    }

    private struct Particle {
        enum Shape { case petal, paper, dot }

        var origin: UnitPoint
        var velocity: CGVector
        var delay: Double
        var size: CGFloat
        var color: Color
        var shape: Shape
        var spin: Double
        var flip: Double
        var phase: Double
        var sway: Double
        var swaySpeed: Double

        static let palette: [Color] = [
            .navy, .stationBlue, .challengeRed, .walkGreen,
            Color(hex: 0xF5C542), Color(hex: 0xF7B6C8), .white,
        ]

        static func random(for burst: Burst) -> Particle {
            let angle = burst.direction + Double.random(in: -burst.spread / 2...burst.spread / 2)
            let speed = Double.random(in: 280...720)
            let isPetal = Double.random(in: 0...1) < 0.3
            return Particle(
                origin: burst.origin,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                delay: burst.delay + Double.random(in: 0...0.12),
                size: isPetal ? .random(in: 10...15) : .random(in: 7...12),
                color: isPetal ? Color(hex: 0xF7B6C8) : palette.randomElement()!,
                shape: isPetal ? .petal : (Bool.random() ? .paper : .dot),
                spin: .random(in: -6...6),
                flip: .random(in: 3...9),
                phase: .random(in: 0...(2 * .pi)),
                sway: .random(in: 8...26),
                swaySpeed: .random(in: 2...4)
            )
        }
    }
}

/// ゆっくり回る放射状の光
struct SunburstView: View {
    var color: Color = .white
    var rays = 18

    var body: some View {
        TimelineView(.animation) { timeline in
            let angle = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 360) * 12
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = max(size.width, size.height)
                let step = 2 * Double.pi / Double(rays)
                for i in 0..<rays {
                    let a = Double(i) * step + angle * .pi / 180
                    var wedge = Path()
                    wedge.move(to: center)
                    wedge.addArc(center: center, radius: radius,
                                 startAngle: .radians(a), endAngle: .radians(a + step / 2), clockwise: false)
                    wedge.closeSubpath()
                    context.fill(wedge, with: .color(color))
                }
            }
        }
        .mask(RadialGradient(colors: [.white, .white.opacity(0)], center: .center, startRadius: 40, endRadius: 210))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
