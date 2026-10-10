import SwiftUI

/// 宿場に着いたときのお祝い画面
struct ArrivalView: View {
    let station: Station
    let progress: JourneyProgress
    @Environment(\.dismiss) private var dismiss

    // 演出の進み具合（順番に true になる）
    @State private var showIllustration = false
    @State private var stamped = false
    @State private var showTitle = false
    @State private var showCards = false
    /// 紙吹雪を打ち出した時刻
    @State private var confettiStart: Date?

    private var course: Course { progress.course }

    private var nextStation: Station? {
        course.stations.first { $0.id == station.id + 1 }
    }

    /// ゴールしたときの文（nil ならふつうの到着の文）
    private var goalMessage: String? {
        guard station.isGoal else { return nil }
        switch course.style {
        case .shukuba: return "\(course.title)を歩きとおしました！"
        case .fudasho: return "八十八ヶ所を巡り終え、結願しました！"
        case .eki: return "\(course.title)を達成しました！"
        }
    }

    /// 紙吹雪の出し方。ゴールは左右から2回打ち上げる
    private var bursts: [ConfettiView.Burst] {
        if station.isGoal {
            return [
                .init(origin: UnitPoint(x: 0.5, y: 0.3), spread: .pi * 1.6, count: 120),
                .init(origin: UnitPoint(x: 0, y: 1), direction: -.pi / 3, spread: .pi / 4, count: 90, delay: 0.5),
                .init(origin: UnitPoint(x: 1, y: 1), direction: -.pi * 2 / 3, spread: .pi / 4, count: 90, delay: 0.5),
                .init(origin: UnitPoint(x: 0, y: 1), direction: -.pi / 3, spread: .pi / 4, count: 80, delay: 1.6),
                .init(origin: UnitPoint(x: 1, y: 1), direction: -.pi * 2 / 3, spread: .pi / 4, count: 80, delay: 1.6),
            ]
        }
        return [.init(origin: UnitPoint(x: 0.5, y: 0.3), spread: .pi * 1.6, count: 140)]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Text(station.isGoal ? (course.style == .fudasho ? "結願" : "ゴール") : station.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.stationBlue, in: Capsule())
                        .padding(.top, 36)
                        .opacity(showIllustration ? 1 : 0)

                    illustration

                    VStack(spacing: 6) {
                        Text(station.name)
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(Color.navy)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .scaleEffect(showTitle ? 1 : 0.3)
                        Text(goalMessage ?? course.style.arrivedMessage)
                            .font(.headline)
                            .foregroundStyle(Color.navy.opacity(0.8))
                    }
                    .opacity(showTitle ? 1 : 0)

                    Group {
                        infoCard
                        progressCard
                    }
                    .opacity(showCards ? 1 : 0)
                    .offset(y: showCards ? 0 : 40)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)

            continueButton
                .opacity(showCards ? 1 : 0)
        }
        .background(
            LinearGradient(colors: [Color.skyBottom, Color.skyTop, .white],
                           startPoint: .top, endPoint: .center)
            .ignoresSafeArea()
        )
        .overlay {
            if let confettiStart {
                ConfettiView(start: confettiStart, bursts: bursts)
                    .ignoresSafeArea()
            }
        }
        .presentationDragIndicator(.visible)
        .task { await playCelebration() }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: stamped)
        .sensoryFeedback(.success, trigger: showTitle)
    }

    /// 光 → イラスト → スタンプと紙吹雪 → 宿場名 → カード の順に見せる
    private func playCelebration() async {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showIllustration = true }
        try? await Task.sleep(for: .milliseconds(550))
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) { stamped = true }
        confettiStart = .now
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { showTitle = true }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { showCards = true }
    }

    /// 宿場の絵と、朱色のスタンプ（後ろに回る光）
    private var illustration: some View {
        StationImage(course: course, station: station)
            .frame(width: 230, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 6))
            .shadow(color: Color.navy.opacity(0.18), radius: 16, y: 8)
            .background {
                SunburstView(color: .white.opacity(0.7))
                    .frame(width: 520, height: 520)
                    .opacity(showIllustration ? 1 : 0)
                    .scaleEffect(showIllustration ? 1 : 0.4)
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    // スタンプを押した衝撃の輪
                    Circle()
                        .stroke(Color.challengeRed, lineWidth: 4)
                        .frame(width: 96, height: 96)
                        .scaleEffect(stamped ? 2.6 : 0.8)
                        .opacity(stamped ? 0 : 0.8)
                        .animation(.easeOut(duration: 0.7), value: stamped)
                    StationStamp(name: station.shortName,
                                 caption: station.isGoal ? course.style.goalStamp : course.style.arrivalStamp)
                        .scaleEffect(stamped ? 1 : 3)
                        .opacity(stamped ? 1 : 0)
                        .rotationEffect(.degrees(stamped ? -12 : -40))
                }
                .offset(x: 34, y: 30)
            }
            .scaleEffect(showIllustration ? 1 : 0.5)
            .opacity(showIllustration ? 1 : 0)
            .padding(.bottom, 20)
    }

    /// 起点から・到着日・次の宿場
    private var infoCard: some View {
        HStack(spacing: 0) {
            InfoItem(symbol: "mappin.and.ellipse", title: "起点から",
                     value: "\(station.cumulativeDistance.kmText) km")
            Divider().frame(height: 40)
            InfoItem(symbol: "calendar", title: "\(course.style.arrivalVerb(for: station))日",
                     value: (progress.arrivalDates[station.id] ?? .now).formatted(.dateTime.month().day()))
            if let nextStation {
                Divider().frame(height: 40)
                InfoItem(symbol: "arrow.right.circle", title: "次は\(nextStation.name)",
                         value: "\(nextStation.distanceFromPrevious.kmText) km")
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    /// コース名と、ここまで歩いた距離・バー
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(course.title)
                    .font(.caption)
                    .foregroundStyle(Color.navy)
                Spacer()
                Text(station.cumulativeDistance.kmText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.navy)
                Text("/ \(course.totalDistance.kmText) km")
                    .font(.caption)
                    .foregroundStyle(Color.navy.opacity(0.7))
            }
            StepBar(fraction: course.totalDistance > 0 ? station.cumulativeDistance / course.totalDistance : 0)
        }
        .padding(16)
        .background(Color.paleBlue, in: RoundedRectangle(cornerRadius: 18))
    }

    private var continueButton: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Spacer()
                Text(station.isGoal ? "閉じる" : "旅を続ける")
                    .font(.headline)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                if !station.isGoal {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(Color.navy, in: Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

/// 情報カードのひとつ分
private struct InfoItem: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.stationBlue)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.navy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 御朱印風の丸いスタンプ
private struct StationStamp: View {
    let name: String
    /// 「到着」「参拝」「踏破」「結願」
    let caption: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.92))
            Circle()
                .stroke(Color.challengeRed, lineWidth: 3.5)
                .padding(3)
            Circle()
                .stroke(Color.challengeRed, lineWidth: 1)
                .padding(9)
            VStack(spacing: 0) {
                Text(caption)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                Text(name)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.challengeRed)
            .padding(.horizontal, 16)
        }
        .frame(width: 96, height: 96)
    }
}

#Preview {
    let course = Course.tokaido
    ArrivalView(station: course.stations[22],
                progress: JourneyProgress(course: course, daily: [], extraKm: 200, startDate: .now))
}
