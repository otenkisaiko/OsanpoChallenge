import SwiftUI

/// コースを始めた後の画面（「全体マップ」と「宿場一覧・札所一覧」を切り替え）
struct JourneyView: View {
    let course: Course
    let progress: JourneyProgress
    let onConnect: () async -> Void

    enum Mode: CaseIterable {
        case map, list

        func title(for style: CheckpointStyle) -> String {
            switch self {
            case .map: "全体マップ"
            case .list: style.listTitle
            }
        }
    }

    @Environment(WalkDataStore.self) private var walkData
    @Environment(WalkSessionStore.self) private var walkSessions
    @AppStorage(StorageKey.healthConnected) private var healthConnected = false
    @AppStorage(StorageKey.dailyStepGoal) private var dailyGoal = 10_000
    @State private var mode = Mode.map

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ModePicker(mode: $mode, style: course.style)
                    .padding(.horizontal, 20)
                if !healthConnected {
                    connectBanner
                        .padding(.horizontal, 20)
                }
                // 今日の「お散歩」で歩いた分
                StepGoalCard(title: "今日の歩数", steps: walkSessions.today.steps, goal: dailyGoal,
                             distanceKm: walkSessions.today.km)
                    .padding(.horizontal, 20)
                if let message = walkSessions.errorMessage ?? walkData.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                switch mode {
                case .map:
                    mapContent
                case .list:
                    StationTimelineView(course: course, progress: progress)
                }
            }
            .padding(.top, 4)
            .background(Color.mapSky.ignoresSafeArea())
            .navigationTitle(mode == .map ? "マップ" : course.style.listTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Station.self) { station in
                StationDetailView(station: station, progress: progress)
            }
        }
    }

    private var mapContent: some View {
        VStack(spacing: 0) {
            JourneyMapView(course: course, progress: progress)
                .overlay(alignment: .bottomLeading) {
                    WalkButton(courseID: course.id, courseTitle: course.title)
                        .padding(16)
                }
            NextStationCard(progress: progress) {
                withAnimation { mode = .list }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: 0xFBFCFE))
        }
    }

    private var connectBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
            Text("ヘルスケアと連携すると、歩いた距離で旅が進みます")
                .font(.caption)
                .foregroundStyle(Color.navy)
            Spacer(minLength: 0)
            Button("連携する") {
                Task { await onConnect() }
            }
            .font(.caption.bold())
            .buttonStyle(.borderedProminent)
            .tint(.navy)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// 「全体マップ / 宿場一覧」の切り替え
private struct ModePicker: View {
    @Binding var mode: JourneyView.Mode
    let style: CheckpointStyle
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JourneyView.Mode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy) { mode = item }
                } label: {
                    Text(item.title(for: style))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(mode == item ? .white : Color.navy)
                        .background {
                            if mode == item {
                                Capsule()
                                    .fill(Color.navy)
                                    .matchedGeometryEffect(id: "selected", in: selection)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.85), in: Capsule())
    }
}

/// マップの下の「次の宿場・次の札所」カード
private struct NextStationCard: View {
    let progress: JourneyProgress
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                StationImage(course: progress.course, station: progress.nextStation ?? progress.currentStation)
                    .frame(width: 68, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    if let next = progress.nextStation {
                        Text("次の\(progress.course.style.noun)")
                            .font(.caption2)
                            .foregroundStyle(Color.navy.opacity(0.7))
                        Text(next.name)
                            .font(.title3.bold())
                            .foregroundStyle(Color.navy)
                        Label("約 \(progress.remainingToNext.kmText) km", systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.navy)
                    } else {
                        Text(progress.course.style == .fudasho ? "結願！" : "ゴール！")
                            .font(.caption2)
                            .foregroundStyle(Color.navy.opacity(0.7))
                        Text("\(progress.currentStation.name)に到着")
                            .font(.title3.bold())
                            .foregroundStyle(Color.navy)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.navy)
            }
            .padding(12)
            .background(Color.paleBlue, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

/// 「お散歩をはじめる / お散歩を終了する」ボタン（マップの左下）
private struct WalkButton: View {
    let courseID: String
    let courseTitle: String
    @Environment(WalkSessionStore.self) private var walkSessions
    @State private var confirmingFinish = false
    @State private var finishedWalk: WalkSession?

    var body: some View {
        Group {
            if let active = walkSessions.active {
                Button {
                    confirmingFinish = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("お散歩を終了する")
                                .font(.subheadline.bold())
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text("\(elapsedText(from: active.start, to: context.date)) ・ \(active.km.formatted(.number.precision(.fractionLength(2)))) km")
                                    .font(.caption2.monospacedDigit())
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.shu, in: Capsule())
                }
            } else {
                Button {
                    walkSessions.start(courseID: courseID)
                } label: {
                    Label("お散歩をはじめる", systemImage: "figure.walk")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color.navy, in: Capsule())
                }
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        .confirmationDialog("お散歩を終了しますか？", isPresented: $confirmingFinish, titleVisibility: .visible) {
            Button("終了する", role: .destructive) {
                Task { finishedWalk = await walkSessions.finish() }
            }
        } message: {
            Text("ここまでに歩いた距離が、\(courseTitle)の旅に加わります。")
        }
        .alert("おつかれさまでした", isPresented: Binding(
            get: { finishedWalk != nil },
            set: { if !$0 { finishedWalk = nil } }
        )) {
            Button("OK") {}
        } message: {
            if let walk = finishedWalk {
                Text("今回のお散歩：\(walk.steps.formatted()) 歩・\(walk.km.kmText) km")
            }
        }
    }

    /// 「12:34」「1:02:03」の形の経過時間
    private func elapsedText(from start: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        let h = seconds / 3600, m = seconds % 3600 / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
