import SwiftUI

/// 宿場一覧・札所一覧：今いるところと、これから向かうところ
struct StationTimelineView: View {
    let course: Course
    let progress: JourneyProgress

    /// 目安時間の計算に使う歩く速さ（km/時）
    private static let walkingSpeedKmh = 4.5

    private var upcoming: [Station] {
        course.stations.filter { $0.id > progress.currentStation.id }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                timelineRow(isCurrent: true, dotKey: .current) {
                    NavigationLink(value: progress.currentStation) {
                        currentCard
                    }
                    .buttonStyle(.plain)
                }
                ForEach(upcoming) { station in
                    timelineRow(isCurrent: false, dotKey: station.id == progress.nextStation?.id ? .next : nil) {
                        NavigationLink(value: station) {
                            upcomingCard(station)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(alignment: .leading) {
                Rectangle()
                    .fill(Color.timelineBlue)
                    .frame(width: 2)
                    .padding(.leading, 13)
                    .padding(.vertical, 30)
            }
            .overlayPreferenceValue(DotAnchorKey.self) { anchors in
                GeometryReader { geo in
                    if let currentAnchor = anchors[.current], let nextAnchor = anchors[.next] {
                        SegmentProgressBar(from: geo[currentAnchor], to: geo[nextAnchor],
                                           fraction: progress.segmentFraction)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(.white)
        .safeAreaInset(edge: .bottom) {
            nextDistanceCard
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white)
        }
    }

    private func timelineRow<Content: View>(isCurrent: Bool, dotKey: DotKey?,
                                            @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            ZStack {
                if isCurrent {
                    // 到着済みの印（現在地の印は、青い線の先に重ねて出す）
                    Circle().fill(.white).frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.stationBlue, lineWidth: 3))
                } else {
                    Circle().fill(Color(hex: 0xEDF6FA)).frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.timelineBlue, lineWidth: 2))
                }
            }
            .frame(width: 28)
            .anchorPreference(key: DotAnchorKey.self, value: .center) { anchor in
                dotKey.map { [$0: anchor] } ?? [:]
            }
            content()
        }
    }

    private var currentCard: some View {
        let station = progress.currentStation
        return HStack(spacing: 14) {
            StationImage(course: course, station: station)
                .frame(width: 84, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(station.isStart ? "出発地" : "現在の\(course.style.noun)")
                    .font(.caption2)
                    .foregroundStyle(Color.stationBlue)
                Text(station.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color.navy)
                if let date = progress.arrivalDates[station.id] {
                    Label("\(date.formatted(.dateTime.month().day()))に\(course.style.arrivalVerb(for: station))",
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.navy)
                }
            }
            Spacer(minLength: 0)
            chevron
        }
        .padding(12)
        .background(Color(hex: 0xE0F3FE), in: RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    private func upcomingCard(_ station: Station) -> some View {
        HStack(spacing: 12) {
            Text("\(station.number ?? station.id)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.stationBlue, in: Circle())
            StationImage(course: course, station: station)
                .frame(width: 56, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(station.name)
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Label("あと 約 \((station.cumulativeDistance - progress.walkedKm).kmText) km",
                      systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Color.navy.opacity(0.8))
            }
            Spacer(minLength: 0)
            chevron
        }
        .padding(10)
        .background(Color(hex: 0xF1F8FD), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.navy.opacity(0.6))
            .padding(.trailing, 4)
    }

    /// 下の「次の宿場まで 約6.8km / 約1時間30分（目安）」
    private var nextDistanceCard: some View {
        HStack(spacing: 14) {
            CourseIcon(course: course, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                if progress.nextStation != nil {
                    Text("次の\(course.style.noun)まで")
                        .font(.caption)
                        .foregroundStyle(Color.navy)
                    Text("約 \(progress.remainingToNext.kmText) km / \(walkingTimeText(km: progress.remainingToNext))（目安）")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.navy)
                } else {
                    Text("\(course.title)を歩きとおしました！")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.navy)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.paleBlue, in: RoundedRectangle(cornerRadius: 16))
    }

    /// 「約1時間30分」（10分単位に丸める）
    private func walkingTimeText(km: Double) -> String {
        let minutes = max(10, Int((km / Self.walkingSpeedKmh * 60 / 10).rounded()) * 10)
        let hours = minutes / 60, rest = minutes % 60
        if hours == 0 { return "約\(rest)分" }
        return rest == 0 ? "約\(hours)時間" : "約\(hours)時間\(rest)分"
    }
}

/// 一覧の丸の印の位置（今いるところと次のところ）
private enum DotKey { case current, next }

private struct DotAnchorKey: PreferenceKey {
    static let defaultValue: [DotKey: Anchor<CGPoint>] = [:]
    static func reduce(value: inout [DotKey: Anchor<CGPoint>], nextValue: () -> [DotKey: Anchor<CGPoint>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// 今いる印から次の印までを 100% として、進んだぶんを上から青い太線で塗る
private struct SegmentProgressBar: View {
    let from: CGPoint
    let to: CGPoint
    let fraction: Double

    var body: some View {
        let f = CGFloat(min(max(fraction, 0), 1))
        let length = (to.y - from.y) * f
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color.walkedRoute)
                .frame(width: 6, height: max(length, 0))
                .position(x: from.x, y: from.y + length / 2)
            // 現在地の印
            ZStack {
                Circle().fill(.white).frame(width: 20, height: 20)
                Circle().fill(Color.walkedRoute).frame(width: 14, height: 14)
                Circle().fill(.white).frame(width: 5, height: 5)
            }
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .position(x: from.x, y: from.y + length)
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.6), value: fraction)
    }
}
