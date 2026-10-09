import Foundation
import Observation

/// 1つのコースのチャレンジ記録
struct CourseChallenge: Codable, Hashable {
    /// チャレンジをはじめた日時。これ以降の、このコースでのお散歩を数える
    var startDate: Date
    /// お祝い画面を出し終えた宿場
    var lastCelebratedStationID = 0
    /// テスト用に足した距離（開発中だけ使う）
    var debugExtraKm = 0.0
}

/// コースごとのチャレンジ記録と、今チャレンジ中のコース。
/// 別のコースに切り替えても記録は残り、あとで続きから再開できる
@MainActor
@Observable
final class ChallengeStore {
    private let defaults = UserDefaults.standard
    private static let challengesKey = "courseChallenges"
    private static let activeKey = "activeCourseID"

    /// コースID → 記録（一度でもはじめたコースだけ）
    private(set) var challenges: [String: CourseChallenge] = [:]
    /// 今チャレンジ中のコース（なければ nil）
    private(set) var activeCourseID: String?

    init() {
        if let data = defaults.data(forKey: Self.challengesKey),
           let saved = try? JSONDecoder().decode([String: CourseChallenge].self, from: data) {
            challenges = saved
        }
        let active = defaults.string(forKey: Self.activeKey) ?? ""
        activeCourseID = active.isEmpty ? nil : active
        migrateFromSingleCourse()
    }

    var activeChallenge: CourseChallenge? {
        activeCourseID.flatMap { challenges[$0] }
    }

    /// 一度でもはじめたことがあるか（やり直すと false に戻る）
    func hasStarted(_ courseID: String) -> Bool {
        challenges[courseID] != nil
    }

    /// 初めてならはじめ、前に歩いたコースなら続きから再開する
    func startOrResume(_ courseID: String) {
        if challenges[courseID] == nil {
            challenges[courseID] = CourseChallenge(startDate: .now)
        }
        activeCourseID = courseID
        save()
    }

    /// そのコースの記録を消して、「はじめる」前の状態に戻す
    func restart(_ courseID: String) {
        challenges[courseID] = nil
        if activeCourseID == courseID {
            activeCourseID = nil
        }
        save()
    }

    func updateActive(_ change: (inout CourseChallenge) -> Void) {
        guard let id = activeCourseID else { return }
        update(id, change)
    }

    func update(_ courseID: String, _ change: (inout CourseChallenge) -> Void) {
        guard var challenge = challenges[courseID] else { return }
        change(&challenge)
        challenges[courseID] = challenge
        save()
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(challenges), forKey: Self.challengesKey)
        defaults.set(activeCourseID ?? "", forKey: Self.activeKey)
    }

    /// 以前の版（東海道だけの記録）から引き継ぐ
    private func migrateFromSingleCourse() {
        guard challenges.isEmpty, let id = activeCourseID else { return }
        let start = defaults.double(forKey: "journeyStartDate")
        challenges[id] = CourseChallenge(
            startDate: start > 0 ? Date(timeIntervalSince1970: start) : .now,
            lastCelebratedStationID: defaults.integer(forKey: "lastCelebratedStationID"),
            debugExtraKm: defaults.double(forKey: "debugExtraKm")
        )
        for key in ["journeyStartDate", "lastCelebratedStationID", "debugExtraKm"] {
            defaults.removeObject(forKey: key)
        }
        save()
    }
}
