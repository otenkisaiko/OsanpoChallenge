import CoreGraphics

/// 折れ線の道のり。「全体の何割の地点はどこか」を計算する
struct RoutePath {
    let points: [CGPoint]
    /// 各頂点までの累積の長さ
    private let lengths: [CGFloat]

    init(points: [CGPoint]) {
        self.points = points
        var acc: [CGFloat] = [0]
        for (a, b) in zip(points, points.dropFirst()) {
            acc.append(acc[acc.count - 1] + hypot(b.x - a.x, b.y - a.y))
        }
        lengths = acc
    }

    var totalLength: CGFloat { lengths.last ?? 0 }

    /// 道のり全体の fraction（0〜1）の地点の座標
    func point(at fraction: Double) -> CGPoint {
        guard points.count > 1, totalLength > 0 else { return points.first ?? .zero }
        let target = CGFloat(min(max(fraction, 0), 1)) * totalLength
        let i = segmentIndex(for: target)
        let segmentLength = lengths[i + 1] - lengths[i]
        let t = segmentLength > 0 ? (target - lengths[i]) / segmentLength : 0
        let a = points[i], b = points[i + 1]
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    /// 起点から fraction の地点までの頂点
    func points(upTo fraction: Double) -> [CGPoint] {
        guard points.count > 1, totalLength > 0 else { return points }
        let target = CGFloat(min(max(fraction, 0), 1)) * totalLength
        let i = segmentIndex(for: target)
        return Array(points[...i]) + [point(at: fraction)]
    }

    private func segmentIndex(for target: CGFloat) -> Int {
        let i = lengths.lastIndex { $0 <= target } ?? 0
        return min(i, points.count - 2)
    }

    /// 通過点をなめらかな曲線（Catmull-Rom）でつないだ頂点列を返す
    static func smoothed(_ controls: [CGPoint], steps: Int = 12) -> [CGPoint] {
        guard controls.count > 2 else { return controls }
        var result: [CGPoint] = []
        for i in 0..<(controls.count - 1) {
            let p0 = controls[max(i - 1, 0)]
            let p1 = controls[i]
            let p2 = controls[i + 1]
            let p3 = controls[min(i + 2, controls.count - 1)]
            for s in 0..<steps {
                let t = CGFloat(s) / CGFloat(steps)
                let t2 = t * t, t3 = t2 * t
                func blend(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
                    0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
                }
                result.append(CGPoint(x: blend(p0.x, p1.x, p2.x, p3.x), y: blend(p0.y, p1.y, p2.y, p3.y)))
            }
        }
        result.append(controls[controls.count - 1])
        return result
    }
}
