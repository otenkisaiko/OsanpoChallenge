import SwiftUI

/// 宿場・札所の詳細（一覧や宿場帳・納経帳から開く）
struct StationDetailView: View {
    let station: Station
    let progress: JourneyProgress

    private var course: Course { progress.course }
    private var guide: StationGuide? { course.guide(for: station) }
    private var summary: CourseSummary? { course.summary }

    /// 「1.品川宿」「起点 日本橋」「1番 霊山寺」
    private var numberedName: String { course.style.numberedName(for: station) }

    var body: some View {
        ScrollView {
            VStack(spacing: -24) {
                Color.clear
                    .frame(height: 300)
                    .overlay {
                        StationImage(course: course, station: station)
                    }
                    .clipped()
                content
                    .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(.white)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let summary {
                Text(summary.category)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.navy.opacity(0.75))
            }
            Text(course.title)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Color.navy)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                (Text(numberedName)
                    .font(.system(size: 26, weight: .heavy))
                 + Text(guide.map { "（\($0.reading)）" } ?? "")
                    .font(.system(size: 17, weight: .bold)))
                    .foregroundStyle(Color.navy)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle()
                    .fill(Color.navy)
                    .frame(height: 1.5)
            }
            .padding(.top, 14)

            statusChip
                .padding(.top, 12)

            if let guide {
                Text(guide.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.sumi.opacity(0.85))
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)

                if let url = guide.wikipediaURL {
                    Link(destination: url) {
                        Label("参考：Wikipedia「\(guide.wikipediaTitle)」", systemImage: "book")
                            .font(.caption)
                    }
                    .tint(Color.stationBlue)
                    .padding(.top, 20)
                }
            }
        }
        .padding(24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 到着済みか、あと何kmか
    private var statusChip: some View {
        Group {
            if let date = progress.arrivalDates[station.id] {
                Label("\(date.formatted(.dateTime.month().day()))に\(course.style.arrivalVerb(for: station))",
                      systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color.challengeRed)
            } else {
                Label("起点から \(station.cumulativeDistance.kmText) km ・ あと \((station.cumulativeDistance - progress.walkedKm).kmText) km",
                      systemImage: "mappin.and.ellipse")
                    .foregroundStyle(Color.navy)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.paleBlue, in: Capsule())
    }
}

/// 宿場のイラスト（無ければ仮の絵）
struct StationImage: View {
    let course: Course
    let station: Station

    var body: some View {
        let name = course.imageName(for: station)
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            Color.paleBlue
        }
    }
}
