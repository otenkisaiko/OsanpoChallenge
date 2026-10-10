import CoreMotion
import Foundation
import Observation

/// 1回分のお散歩
struct WalkSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var start: Date
    /// 終了した時刻（お散歩中は nil）
    var end: Date?
    var steps = 0
    var km = 0.0
    /// このお散歩を数えるコース（以前の版の記録は nil ＝東海道）
    var courseID: String?
}

/// 「お散歩をはじめる」〜「お散歩を終了する」の記録。
/// お散歩中は iPhone の歩数計（CoreMotion）でその場の歩数・距離を測り、終了時に保存する
@MainActor
@Observable
final class WalkSessionStore {
    private let pedometer = CMPedometer()
    private let defaults = UserDefaults.standard
    private static let sessionsKey = "walkSessions"
    private static let activeKey = "activeWalkSession"

    /// 終了したお散歩
    private(set) var sessions: [WalkSession] = []
    /// お散歩中の記録
    private(set) var active: WalkSession?
    private(set) var errorMessage: String?

    var isWalking: Bool { active != nil }
    var isAvailable: Bool { CMPedometer.isStepCountingAvailable() && CMPedometer.isDistanceAvailable() }

    init() {
        load()
        if active != nil {
            // アプリを閉じている間もお散歩は続いている
            startLiveUpdates()
        }
    }

    /// そのコースの、指定日以降のお散歩（お散歩中の分も含む）
    func sessions(for courseID: String, since date: Date) -> [WalkSession] {
        allSessions.filter { ($0.courseID ?? Course.tokaido.id) == courseID && $0.start >= date }
    }

    private var allSessions: [WalkSession] {
        sessions + [active].compactMap { $0 }
    }

    /// 今日のお散歩の合計（コースに関係なく）
    var today: (steps: Int, km: Double) {
        total(since: Calendar.current.startOfDay(for: .now))
    }

    /// 今週のお散歩の合計（コースに関係なく。週の始まりは端末の暦の設定に従う）
    var thisWeek: (steps: Int, km: Double) {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? calendar.startOfDay(for: .now)
        return total(since: start)
    }

    private func total(since start: Date) -> (steps: Int, km: Double) {
        let walks = allSessions.filter { $0.start >= start }
        return (walks.reduce(0) { $0 + $1.steps }, walks.reduce(0) { $0 + $1.km })
    }

    func start(courseID: String) {
        guard !isWalking else { return }
        guard isAvailable else {
            errorMessage = "この端末では歩数を計測できません"
            return
        }
        errorMessage = nil
        active = WalkSession(start: .now, courseID: courseID)
        save()
        startLiveUpdates()
    }

    /// お散歩を終了して保存する。保存したお散歩を返す
    @discardableResult
    func finish() async -> WalkSession? {
        guard var session = active else { return nil }
        pedometer.stopUpdates()
        let end = Date()
        if let data = try? await query(from: session.start, to: end) {
            session.steps = max(session.steps, data.steps)
            session.km = max(session.km, data.km)
        }
        session.end = end
        sessions.append(session)
        active = nil
        save()
        return session
    }

    private func startLiveUpdates() {
        guard let start = active?.start, isAvailable else { return }
        pedometer.startUpdates(from: start) { [weak self] data, error in
            let steps = data?.numberOfSteps.intValue
            let km = data?.distance.map { $0.doubleValue / 1000 }
            let failed = error != nil
            Task { @MainActor in
                guard let self, var session = self.active else { return }
                if failed {
                    self.errorMessage = "歩数を計測できません。設定アプリで「モーションとフィットネス」を許可してください"
                    return
                }
                if let steps { session.steps = steps }
                if let km { session.km = km }
                self.active = session
                self.save()
            }
        }
    }

    private func query(from start: Date, to end: Date) async throws -> (steps: Int, km: Double) {
        try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let data {
                    continuation.resume(returning: (data.numberOfSteps.intValue, (data.distance?.doubleValue ?? 0) / 1000))
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.featureUnsupported))
                }
            }
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Self.sessionsKey),
           let saved = try? decoder.decode([WalkSession].self, from: data) {
            sessions = saved
        }
        if let data = defaults.data(forKey: Self.activeKey) {
            active = try? decoder.decode(WalkSession.self, from: data)
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        defaults.set(try? encoder.encode(sessions), forKey: Self.sessionsKey)
        if let active {
            defaults.set(try? encoder.encode(active), forKey: Self.activeKey)
        } else {
            defaults.removeObject(forKey: Self.activeKey)
        }
    }
}
