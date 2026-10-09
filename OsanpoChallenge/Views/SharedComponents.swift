import SwiftUI

/// 「今日の歩数」「今週の歩数」の白いカード
struct StepGoalCard: View {
    let title: String
    let steps: Int
    let goal: Int
    /// 指定すると右側に距離を出す
    var distanceKm: Double? = nil
    var distanceTitle = "今日の距離"

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.walk")
                .font(.system(size: distanceKm == nil ? 30 : 26, weight: .semibold))
                .foregroundStyle(Color.navy)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.navy)
                    Spacer()
                    Text("目標 \(goal.formatted()) 歩")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack(spacing: 12) {
                    // 数字は改行させない。入りきらないときは少し縮め、バーのほうを短くする
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(steps.formatted())
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("歩")
                            .font(.caption)
                            .fixedSize()
                    }
                    .foregroundStyle(Color.navy)
                    .layoutPriority(1)
                    StepBar(fraction: goal > 0 ? Double(steps) / Double(goal) : 0)
                        .frame(minWidth: 24)
                }
            }
            if let distanceKm {
                Rectangle()
                    .fill(Color(hex: 0xE2EFF7))
                    .frame(width: 1, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    Text(distanceTitle)
                        .font(.caption)
                        .foregroundStyle(Color.navy)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(distanceKm.kmText)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .lineLimit(1)
                        Text("km")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.navy)
                }
                .fixedSize()
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }
}

/// 歩数の進捗バー
struct StepBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0xE2EFF7))
                Capsule().fill(Color.walkGreen)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 10)
    }
}

/// コースの丸いアイコン（コースの画像を丸く切り抜く）
struct CourseIcon: View {
    let course: Course
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let name = course.summary?.imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.paleBlue
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 2))
    }
}
