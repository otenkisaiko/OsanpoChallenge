import SwiftUI

/// イラストの地図と、歩いた道のり・現在地。
/// 2本指で拡大・縮小、1本指でドラッグ移動できる
struct JourneyMapView: View {
    let course: Course
    let progress: JourneyProgress

    /// 拡大率（1 = 全体表示）
    @State private var zoom: CGFloat = 1
    /// 表示位置のずらし量
    @State private var pan: CGSize = .zero
    /// ジェスチャー開始時の値
    @State private var gestureStart: (zoom: CGFloat, pan: CGSize)?

    private let maxZoom: CGFloat = 8
    /// 右下のボタンで現在地へ寄るときの拡大率
    private let focusZoom: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let camera = MapCamera(mapSize: course.mapSize, viewSize: geo.size, zoom: zoom, pan: pan)
            let path = RoutePath(points: course.route.map(camera.toView))
            let walkedFraction = course.pathFraction(forDistance: progress.walkedKm)
            let current = path.point(at: walkedFraction)

            ZStack {
                if let imageName = course.mapImageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: camera.imageRect.width, height: camera.imageRect.height)
                        .position(x: camera.imageRect.midX, y: camera.imageRect.midY)
                }
                routeCanvas(path: path, walkedFraction: walkedFraction)
                CurrentMarker()
                    .position(current)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture(viewSize: geo.size).simultaneously(with: magnifyGesture(viewSize: geo.size)))
            .onTapGesture(count: 2) {
                withAnimation(.snappy) { focus(on: current, viewSize: geo.size) }
            }
            .overlay(alignment: .topLeading) {
                courseBadge
                    .padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    withAnimation(.snappy) {
                        if zoom > 1.05 {
                            zoom = 1
                            pan = .zero
                        } else {
                            focus(on: current, viewSize: geo.size)
                        }
                    }
                } label: {
                    Image(systemName: zoom > 1.05 ? "arrow.down.right.and.arrow.up.left" : "location.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.navy)
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                }
                .accessibilityLabel(zoom > 1.05 ? "全体を表示" : "現在地を拡大")
                .padding(16)
            }
        }
        .background(Color(hex: 0xC0EAF9))
    }

    // MARK: - 表示位置の操作

    /// 現在地を画面の中央にして拡大する
    private func focus(on point: CGPoint, viewSize: CGSize) {
        // point は今の表示での座標。拡大前（zoom 1・pan 0）の座標に戻してから寄せる
        let base = MapCamera(mapSize: course.mapSize, viewSize: viewSize, zoom: zoom, pan: pan).toBase(point)
        zoom = focusZoom
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        pan = CGSize(width: -(base.x - center.x) * zoom, height: -(base.y - center.y) * zoom)
        pan = MapCamera.clampedPan(pan, mapSize: course.mapSize, viewSize: viewSize, zoom: zoom)
    }

    private func dragGesture(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let start = gestureStart ?? (zoom, pan)
                gestureStart = start
                let proposed = CGSize(width: start.pan.width + value.translation.width,
                                      height: start.pan.height + value.translation.height)
                pan = MapCamera.clampedPan(proposed, mapSize: course.mapSize, viewSize: viewSize, zoom: zoom)
            }
            .onEnded { _ in gestureStart = nil }
    }

    private func magnifyGesture(viewSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = gestureStart ?? (zoom, pan)
                gestureStart = start
                let newZoom = min(max(start.zoom * value.magnification, 1), maxZoom)
                // 指で挟んだ位置が動かないように拡大する
                let anchor = value.startLocation
                let startCamera = MapCamera(mapSize: course.mapSize, viewSize: viewSize, zoom: start.zoom, pan: start.pan)
                let base = startCamera.toBase(anchor)
                let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
                let proposed = CGSize(width: anchor.x - center.x - (base.x - center.x) * newZoom,
                                      height: anchor.y - center.y - (base.y - center.y) * newZoom)
                zoom = newZoom
                pan = MapCamera.clampedPan(proposed, mapSize: course.mapSize, viewSize: viewSize, zoom: newZoom)
            }
            .onEnded { _ in gestureStart = nil }
    }

    // MARK: - 描画

    private func routeCanvas(path: RoutePath, walkedFraction: Double) -> some View {
        Canvas { context, _ in
            var whole = Path()
            whole.addLines(path.points)
            // まだ歩いていない道：白い線に水色の点線（イラストの道と同じ見た目）
            context.stroke(whole, with: .color(.white),
                           style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
            context.stroke(whole, with: .color(Color.routeDash),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 6]))
            // 歩いた道：白い線の幅いっぱいを青く塗る
            var walked = Path()
            walked.addLines(path.points(upTo: walkedFraction))
            context.stroke(walked, with: .color(Color.walkedRoute),
                           style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
    }

    /// 左上の「東海道五十三次 全 53 宿」
    private var courseBadge: some View {
        HStack(spacing: 10) {
            CourseIcon(course: course, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(course.title)
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Text("\(course.badgeText) ・ \(progress.walkedKm.kmText) km 進んだ")
                    .font(.caption)
                    .foregroundStyle(Color.navy)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// 地図の座標 → 画面の座標の変換。
/// 拡大率 1 のときは地図が表示領域いっぱい（はみ出しは中央で切る）になる
private struct MapCamera {
    let viewSize: CGSize
    let zoom: CGFloat
    let pan: CGSize
    /// 拡大率 1 のときの地図の縮尺と位置
    let baseScale: CGFloat
    let baseOrigin: CGPoint
    let mapSize: CGSize

    init(mapSize: CGSize, viewSize: CGSize, zoom: CGFloat, pan: CGSize) {
        self.mapSize = mapSize
        self.viewSize = viewSize
        self.zoom = zoom
        self.pan = pan
        baseScale = max(viewSize.width / mapSize.width, viewSize.height / mapSize.height)
        baseOrigin = CGPoint(x: (viewSize.width - mapSize.width * baseScale) / 2,
                             y: (viewSize.height - mapSize.height * baseScale) / 2)
    }

    private var center: CGPoint { CGPoint(x: viewSize.width / 2, y: viewSize.height / 2) }

    /// 拡大率 1 の画面座標 → 今の画面座標
    private func transform(_ base: CGPoint) -> CGPoint {
        CGPoint(x: center.x + (base.x - center.x) * zoom + pan.width,
                y: center.y + (base.y - center.y) * zoom + pan.height)
    }

    /// 今の画面座標 → 拡大率 1 の画面座標
    func toBase(_ point: CGPoint) -> CGPoint {
        CGPoint(x: center.x + (point.x - center.x - pan.width) / zoom,
                y: center.y + (point.y - center.y - pan.height) / zoom)
    }

    /// 地図画像の座標 → 今の画面座標
    func toView(_ mapPoint: CGPoint) -> CGPoint {
        transform(CGPoint(x: baseOrigin.x + mapPoint.x * baseScale, y: baseOrigin.y + mapPoint.y * baseScale))
    }

    /// 地図画像が今の画面のどこに表示されるか
    var imageRect: CGRect {
        let topLeft = toView(.zero)
        return CGRect(x: topLeft.x, y: topLeft.y,
                      width: mapSize.width * baseScale * zoom, height: mapSize.height * baseScale * zoom)
    }

    /// 地図の外（何もない所）が見えないように、ずらし量を制限する
    static func clampedPan(_ pan: CGSize, mapSize: CGSize, viewSize: CGSize, zoom: CGFloat) -> CGSize {
        let unpanned = MapCamera(mapSize: mapSize, viewSize: viewSize, zoom: zoom, pan: .zero).imageRect
        // 画像の左端が 0 以下、右端が幅以上になる範囲
        let minX = viewSize.width - unpanned.maxX, maxX = -unpanned.minX
        let minY = viewSize.height - unpanned.maxY, maxY = -unpanned.minY
        return CGSize(width: min(max(pan.width, minX), maxX),
                      height: min(max(pan.height, minY), maxY))
    }
}

/// 現在地の印（小さめ。拡大しても大きさは変わらない）
private struct CurrentMarker: View {
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 16, height: 16)
            Circle().fill(Color.navy).frame(width: 10, height: 10)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        .allowsHitTesting(false)
    }
}
