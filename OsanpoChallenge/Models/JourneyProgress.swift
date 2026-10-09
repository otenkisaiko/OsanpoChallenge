import Foundation

/// 1日分の歩いた距離
struct DailyWalk: Hashable {
    let date: Date
    let km: Double
}

/// 歩いた記録から計算した、コース上の進み具合
struct JourneyProgress {
    let course: Course
    /// 旅の開始から歩いた距離（km、ゴールで打ち止め）
    let walkedKm: Double
    /// チェックポイントID → 到着した日
    let arrivalDates: [Int: Date]

    init(course: Course, daily: [DailyWalk], extraKm: Double, startDate: Date) {
        self.course = course
        var dates: [Int: Date] = [0: startDate]
        var total = 0.0
        var next = 1
        var records = daily.sorted { $0.date < $1.date }
        if extraKm > 0 {
            records.append(DailyWalk(date: .now, km: extraKm))
        }
        for record in records {
            total += record.km
            while next < course.stations.count, course.stations[next].cumulativeDistance <= total {
                dates[next] = record.date
                next += 1
            }
        }
        walkedKm = min(total, course.totalDistance)
        arrivalDates = dates
    }

    /// 最後に到着したチェックポイント
    var currentStation: Station {
        course.stations.last { $0.cumulativeDistance <= walkedKm } ?? course.stations[0]
    }

    /// 次のチェックポイント（ゴール済みなら nil）
    var nextStation: Station? {
        course.stations.first { $0.cumulativeDistance > walkedKm }
    }

    var remainingToNext: Double {
        (nextStation?.cumulativeDistance ?? walkedKm) - walkedKm
    }

    /// 今いる区間の進み具合（0〜1）
    var segmentFraction: Double {
        guard let next = nextStation, next.distanceFromPrevious > 0 else { return 1 }
        return (walkedKm - currentStation.cumulativeDistance) / next.distanceFromPrevious
    }

    var totalFraction: Double {
        course.totalDistance > 0 ? walkedKm / course.totalDistance : 0
    }

    var isFinished: Bool { nextStation == nil }
}
