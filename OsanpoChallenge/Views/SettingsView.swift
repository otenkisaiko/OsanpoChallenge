import SwiftUI

struct SettingsView: View {
    @Environment(ChallengeStore.self) private var challenges
    @Environment(WalkSessionStore.self) private var walkSessions
    @AppStorage(StorageKey.weeklyStepGoal) private var weeklyGoal = 50_000
    @AppStorage(StorageKey.dailyStepGoal) private var dailyGoal = 10_000
    /// やり直しを確認中のコース
    @State private var restartTarget: Course?

    /// 一度でもはじめたコース（ホームの並び順）
    private var startedCourses: [Course] {
        Course.playable.filter { challenges.hasStarted($0.id) }
    }

    /// そのコースで進んだ距離
    private func walkedKm(_ course: Course) -> Double {
        guard let challenge = challenges.challenges[course.id] else { return 0 }
        let walks = walkSessions.sessions(for: course.id, since: challenge.startDate)
            .map { DailyWalk(date: $0.end ?? .now, km: $0.km) }
        return JourneyProgress(course: course, daily: walks, extraKm: challenge.debugExtraKm,
                               startDate: challenge.startDate).walkedKm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("マイページ")
                            .font(.title2.bold())
                            .foregroundStyle(Color.navy)
                        WalkRecordCard(sessions: walkSessions.sessions)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                }

                Section {
                    if startedCourses.isEmpty {
                        Text("はじめたコースはありません")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(startedCourses, id: \.id) { course in
                        courseRow(course)
                    }
                } header: {
                    sectionHeader("旅", systemImage: "map")
                } footer: {
                    Text("開始日からの「お散歩」で歩いた距離の合計で、コースを進みます。別のコースに切り替えても、それまでの記録は残ります。")
                }

                Section {
                    Stepper(value: $dailyGoal, in: 1_000...50_000, step: 1_000) {
                        LabeledContent("1日の目標") {
                            Text("\(dailyGoal.formatted()) 歩").foregroundStyle(Color.navy)
                        }
                    }
                    Stepper(value: $weeklyGoal, in: 5_000...200_000, step: 5_000) {
                        LabeledContent("今週の目標") {
                            Text("\(weeklyGoal.formatted()) 歩").foregroundStyle(Color.navy)
                        }
                    }
                } header: {
                    sectionHeader("目標", systemImage: "flag")
                }

                Section {
                    Text("ホームの「今週の歩数」は、iPhoneの「ヘルスケア」から読み込みます。許可を変えるときは、ヘルスケアAppの「共有」→「Appとサービス」から設定してください。")
                        .font(.footnote)
                        .foregroundStyle(Color.sumi.opacity(0.85))
                } header: {
                    sectionHeader("ヘルスケア", systemImage: "heart")
                }

                #if DEBUG
                if let expiration = DevSigning.expirationDate {
                    Section {
                        LabeledContent("アプリの有効期限") {
                            Text(expiration.formatted(.dateTime.month().day().hour().minute()))
                                .foregroundStyle(DevSigning.isExpiringSoon ? Color.challengeRed : Color.navy)
                        }
                    } header: {
                        sectionHeader("開発用", systemImage: "clock")
                    } footer: {
                        Text("無料の Apple ID で入れたアプリは7日で使えなくなります。期限が近づいたら、Mac につないで入れ直してください。")
                    }
                }
                if let challenge = challenges.activeChallenge {
                    Section {
                        LabeledContent("追加した距離", value: "\(challenge.debugExtraKm.kmText) km")
                        Button("+1 km") { challenges.updateActive { $0.debugExtraKm += 1 } }
                        Button("+10 km") { challenges.updateActive { $0.debugExtraKm += 10 } }
                        Button("+100 km") { challenges.updateActive { $0.debugExtraKm += 100 } }
                        Button("リセット", role: .destructive) { challenges.updateActive { $0.debugExtraKm = 0 } }
                    } header: {
                        sectionHeader("テスト用（開発中だけ表示）", systemImage: "hammer")
                    }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: 0xFAFDFE))
            .statusBarBackground(Color(hex: 0xFAFDFE))
            .tint(.navy)
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("旅を最初からやり直しますか？",
                                isPresented: Binding(get: { restartTarget != nil }, set: { if !$0 { restartTarget = nil } }),
                                titleVisibility: .visible,
                                presenting: restartTarget) { course in
                Button("やり直す", role: .destructive) {
                    challenges.restart(course.id)
                }
            } message: { course in
                Text("「\(course.title)」の記録が消え、「チャレンジをはじめる」からになります。")
            }
        }
    }

    /// はじめたコース1つ分：名前・状態・開始日・進んだ距離・やり直し
    @ViewBuilder
    private func courseRow(_ course: Course) -> some View {
        let isActive = challenges.activeCourseID == course.id
        HStack(spacing: 12) {
            CourseIcon(course: course, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundStyle(Color.navy)
                    Text(isActive ? "チャレンジ中" : "中断中")
                        .font(.caption2.bold())
                        .foregroundStyle(isActive ? Color.challengeRed : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(Capsule().stroke(isActive ? Color.challengeRed : Color.secondary.opacity(0.5), lineWidth: 1))
                }
                Text("\(walkedKm(course).kmText) / \(course.totalDistance.kmText) km 進んだ")
                    .font(.caption)
                    .foregroundStyle(Color.navy.opacity(0.75))
            }
        }
        .padding(.vertical, 4)
        DatePicker("旅の開始日", selection: startDateBinding(course), in: ...Date.now, displayedComponents: .date)
        Button("\(course.title)を最初からやり直す", role: .destructive) {
            restartTarget = course
        }
    }

    private func startDateBinding(_ course: Course) -> Binding<Date> {
        Binding(
            get: { challenges.challenges[course.id]?.startDate ?? .now },
            set: { date in challenges.update(course.id) { $0.startDate = Calendar.current.startOfDay(for: date) } }
        )
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.bold())
            .foregroundStyle(Color.navy)
            .textCase(nil)
    }
}

/// 「これまでのお散歩」：回数・合計距離・合計歩数
private struct WalkRecordCard: View {
    let sessions: [WalkSession]

    /// 歩いた記録のあるお散歩だけ数える（ボタンを試しに押しただけの記録は除く）
    private var walks: [WalkSession] { sessions.filter { $0.steps > 0 } }

    /// 地球1周（赤道の長さ）
    private static let earthCircumferenceKm = 40_075.0

    /// 合計距離が地球何周分か。「0.003」、小さいうちは「0.0002」、1周を超えたら「1.25」
    private var earthLapsText: String {
        let laps = walks.reduce(0) { $0 + $1.km } / Self.earthCircumferenceKm
        let digits = laps >= 1 ? 2 : (laps >= 0.001 || laps == 0 ? 3 : 4)
        return laps.formatted(.number.precision(.fractionLength(digits)))
    }

    private var totalKm: Double { walks.reduce(0) { $0 + $1.km } }
    private var totalSteps: Int { walks.reduce(0) { $0 + $1.steps } }

    /// 1万km以上は小数を省く（「40,075」）
    private var totalKmText: String {
        totalKm >= 10_000 ? Int(totalKm).formatted() : totalKm.kmText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("これまでのお散歩", systemImage: "figure.walk")
                .font(.subheadline.bold())
                .foregroundStyle(Color.navy)
            // 欄の幅は、入る桁数に合わせて配分する（地球1周 ≒ 4,800万歩・40,075km まで入るように）
            GeometryReader { geo in
                let widths = Self.columnWidths(total: geo.size.width - 3)
                HStack(alignment: .top, spacing: 0) {
                    stat(title: "回数", value: walks.count.formatted(), unit: "回")
                        .frame(width: widths[0])
                    Divider()
                    stat(title: "合計距離", value: totalKmText, unit: "km")
                        .frame(width: widths[1])
                    Divider()
                    stat(title: "合計歩数", value: totalSteps.formatted(), unit: "歩")
                        .frame(width: widths[2])
                    Divider()
                    stat(title: "地球換算", value: earthLapsText, unit: "周")
                        .frame(width: widths[3])
                }
            }
            .frame(height: 48)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    /// 回数は狭く、歩数はいちばん広く
    private static func columnWidths(total: CGFloat) -> [CGFloat] {
        let weights: [CGFloat] = [0.6, 1.1, 1.35, 0.95]
        let sum = weights.reduce(0, +)
        return weights.map { max(0, total) * $0 / sum }
    }

    private func stat(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(unit)
                    .font(.caption2)
                    .fixedSize()
            }
            .foregroundStyle(Color.navy)
            .padding(.horizontal, 3)
            .frame(height: 28)
        }
    }
}
