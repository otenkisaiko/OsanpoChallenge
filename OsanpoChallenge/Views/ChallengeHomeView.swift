import SwiftUI

/// ホーム：今週の歩数と、チャレンジ（コース）の一覧
struct ChallengeHomeView: View {
    let onStart: (CourseSummary) -> Void

    @Environment(WalkSessionStore.self) private var walkSessions
    @AppStorage(StorageKey.weeklyStepGoal) private var weeklyGoal = 50_000
    @Environment(ChallengeStore.self) private var challenges
    @State private var path: [CourseSummary] = []

    var body: some View {
        NavigationStack(path: $path) {
            list
                .navigationDestination(for: CourseSummary.self) { course in
                    CourseDetailView(course: course) { selected in
                        onStart(selected)
                        path = []
                    }
                }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("お散歩チャレンジ")
                    .font(.title2.bold())
                    .foregroundStyle(Color.navy)
                    .padding(.top, 8)
                #if DEBUG
                if DevSigning.isExpiringSoon, let expiration = DevSigning.expirationDate {
                    Label("アプリの有効期限は \(expiration.formatted(.dateTime.month().day().hour().minute())) です。Mac につないで入れ直してください（開発中だけの表示）",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.challengeRed)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.challengeRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                #endif
                weekCard
                Text("チャレンジを選ぶ")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                    .padding(.top, 4)
                VStack(spacing: 14) {
                    ForEach(CourseCatalog.visible) { course in
                        NavigationLink(value: course) {
                            CourseCard(course: course, isActive: course.id == challenges.activeCourseID)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color(hex: 0xFAFDFE))
        .statusBarBackground(Color(hex: 0xFAFDFE))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var weekCard: some View {
        // マイページの合計と同じく、お散歩中に歩いた分だけを数える
        StepGoalCard(title: "今週の歩数", steps: walkSessions.thisWeek.steps, goal: weeklyGoal,
                     distanceKm: walkSessions.thisWeek.km, distanceTitle: "今週の距離")
    }
}

/// コースのカード
private struct CourseCard: View {
    let course: CourseSummary
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            CourseImage(name: course.imageName, tint: course.themeColor)
                .frame(width: 112, height: 100)
                .clipped()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundStyle(Color.navy)
                    if isActive {
                        Text("チャレンジ中")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.challengeRed)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white, in: Capsule())
                            .overlay(Capsule().stroke(Color.challengeRed, lineWidth: 1))
                    } else if !course.isAvailable {
                        Text("準備中")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.navy.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.8), in: Capsule())
                    }
                }
                Text(course.catchphrase)
                    .font(.caption)
                    .foregroundStyle(Color.navy.opacity(0.75))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Label("約 \(course.distanceText) km", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.navy)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.navy)
                .padding(.trailing, 16)
        }
        .background(course.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ChallengeHomeView(onStart: { _ in })
        .environment(WalkSessionStore())
}
