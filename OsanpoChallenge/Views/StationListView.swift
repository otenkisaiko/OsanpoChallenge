import SwiftUI

/// 宿場帳・納経帳：すべてのチェックポイントをイラストで並べる。到着したところにはスタンプ
struct StationListView: View {
    let progress: JourneyProgress

    private var course: Course { progress.course }
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(course.style.bookTitle)
                        .font(.title2.bold())
                        .foregroundStyle(Color.navy)
                        .padding(.top, 8)
                    summaryCard
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(course.stations) { station in
                            NavigationLink(value: station) {
                                StationTile(station: station, progress: progress)
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
            .navigationDestination(for: Station.self) { station in
                StationDetailView(station: station, progress: progress)
            }
        }
    }

    /// コース名・歩いた距離とバー
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CourseIcon(course: course, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundStyle(Color.navy)
                    Text("\(progress.walkedKm.kmText) / \(course.totalDistance.kmText) km")
                        .font(.caption)
                        .foregroundStyle(Color.navy.opacity(0.7))
                }
                Spacer()
            }
            StepBar(fraction: progress.totalFraction)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }
}

/// 宿場帳の1マス
private struct StationTile: View {
    let station: Station
    let progress: JourneyProgress

    private var arrival: Date? { progress.arrivalDates[station.id] }
    private var isCurrent: Bool { station.id == progress.currentStation.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(1.37, contentMode: .fit)
                .overlay {
                    StationImage(course: progress.course, station: station)
                        .saturation(arrival == nil ? 0.15 : 1)
                        .opacity(arrival == nil ? 0.7 : 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrent ? Color.stationBlue : .clear, lineWidth: 3)
                }
                .overlay(alignment: .topTrailing) {
                    // 東海道の起点は出発地なので「到着」スタンプは付けない（お遍路は1番札所から参拝する）
                    if arrival != nil && (!station.isStart || progress.course.style.stampsStart) {
                        MiniStamp(caption: progress.course.style.arrivalStamp)
                            .offset(x: 6, y: -6)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    badge
                        .padding(8)
                }
                .shadow(color: .black.opacity(arrival == nil ? 0 : 0.08), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.label)
                    .font(.caption2)
                    .foregroundStyle(Color.navy.opacity(0.6))
                Text(station.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 2)
        }
    }

    /// 左下：到着日・いまここ・あと◯km
    @ViewBuilder
    private var badge: some View {
        if isCurrent && !station.isGoal {
            label("いまここ", color: .stationBlue)
        } else if let arrival {
            label(arrival.formatted(.dateTime.month().day()), color: .navy)
        } else {
            label("あと \((station.cumulativeDistance - progress.walkedKm).kmText) km", color: .navy.opacity(0.75))
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }
}

/// サムネイルの右上の小さな「到着」スタンプ
private struct MiniStamp: View {
    let caption: String

    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().stroke(Color.challengeRed, lineWidth: 2).padding(2)
            Circle().stroke(Color.challengeRed, lineWidth: 0.8).padding(5)
            Text(caption)
                .font(.system(size: 11, weight: .heavy, design: .serif))
                .foregroundStyle(Color.challengeRed)
        }
        .frame(width: 42, height: 42)
        .rotationEffect(.degrees(-12))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}
