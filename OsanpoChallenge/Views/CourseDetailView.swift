import SwiftUI

/// コースの詳細（ホームでコースを選んだ後の画面）
struct CourseDetailView: View {
    let course: CourseSummary
    let onStart: (CourseSummary) -> Void

    @Environment(ChallengeStore.self) private var challenges

    var body: some View {
        ScrollView {
            VStack(spacing: -24) {
                Color.clear
                    .frame(height: 340)
                    .overlay {
                        Image(course.heroImageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                content
                    .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(.white)
        .safeAreaInset(edge: .bottom) { startButton }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(course.category)
                .font(.caption.weight(.medium))
                .foregroundStyle(course.themeColor.opacity(0.75))
            Text(course.title)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(course.themeColor)
                .padding(.top, 6)
            Text(course.description)
                .font(.subheadline)
                .foregroundStyle(Color.sumi.opacity(0.85))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            Divider().padding(.vertical, 18)
            stats
            Divider().padding(.vertical, 18)

            if !course.highlightPlaces.isEmpty {
                sectionTitle("主な宿場町")
                FlowLayout(spacing: 8) {
                    ForEach(course.highlightPlaces, id: \.self) { place in
                        Text(place)
                            .font(.caption)
                            .foregroundStyle(course.themeColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(course.cardColor.opacity(0.7), in: Capsule())
                    }
                }
            }

            if !course.highlights.isEmpty {
                sectionTitle("見どころ")
                VStack(spacing: 8) {
                    ForEach(course.highlights, id: \.self) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.symbol)
                                .foregroundStyle(course.themeColor)
                                .frame(width: 24)
                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(Color.sumi)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(course.cardColor.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Text("※目安日数は、1日1万歩（約\(Int(CourseSummary.dailyPaceKm))km）歩いた場合")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            StatItem(symbol: "mappin.and.ellipse", title: "全長",
                     value: "約 \(Int(course.distanceKm.rounded()).formatted()) km", tint: course.themeColor)
            Divider().frame(height: 36)
            StatItem(symbol: "figure.walk", title: "目安日数",
                     value: "約 \(course.estimatedDays) 日", tint: course.themeColor)
            Divider().frame(height: 36)
            StatItem(symbol: "chart.bar.fill", title: "難易度",
                     value: course.difficulty, tint: course.themeColor)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(course.themeColor)
            .padding(.bottom, 12)
    }

    private var startButtonTitle: String {
        if !course.isAvailable { return "準備中" }
        return challenges.hasStarted(course.id) ? "チャレンジを再開する" : "チャレンジをはじめる"
    }

    private var startButton: some View {
        Button {
            onStart(course)
        } label: {
            HStack {
                Spacer()
                Text(startButtonTitle)
                    .font(.headline)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                if course.isAvailable {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(course.isAvailable ? course.themeColor : Color.gray.opacity(0.5), in: Capsule())
        }
        .disabled(!course.isAvailable)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.white)
    }
}

/// 全長・目安日数・難易度のひとつ分
private struct StatItem: View {
    let symbol: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(Color.sumi)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// 横に並べて、はみ出したら折り返すレイアウト（宿場町のチップ用）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: CourseCatalog.all[0], onStart: { _ in })
    }
}
