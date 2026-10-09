import Foundation
import HealthKit
import Observation

/// iPhone の「ヘルスケア」から、1日・1週間の歩数と歩行距離を読み込む（ホーム画面の表示用）
@MainActor
@Observable
final class WalkDataStore {
    private let healthStore = HKHealthStore()

    private(set) var todaySteps = 0
    private(set) var todayKm = 0.0
    private(set) var weekSteps = 0
    private(set) var weekKm = 0.0
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var isHealthAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// ヘルスケアの読み取り許可を求める（許可画面は初回だけ表示される）
    func requestAuthorization() async {
        guard isHealthAvailable else {
            errorMessage = "この端末ではヘルスケアを利用できません"
            return
        }
        let types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
        ]
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
        } catch {
            errorMessage = "ヘルスケアの許可を求められませんでした"
        }
    }

    func refresh() async {
        guard isHealthAvailable else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let today = Calendar.current.startOfDay(for: .now)
            todayKm = try await sum(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), since: today)
            todaySteps = Int(try await sum(.stepCount, unit: .count(), since: today))
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? today
            weekSteps = Int(try await sum(.stepCount, unit: .count(), since: weekStart))
            weekKm = try await sum(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), since: weekStart)
            errorMessage = nil
        } catch {
            errorMessage = "歩行データを読み込めませんでした"
        }
    }

    private func sum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, since start: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(identifier), predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let statistics = try await descriptor.result(for: healthStore)
            return statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } catch let error as HKError where error.code == .errorNoData {
            return 0
        }
    }
}
