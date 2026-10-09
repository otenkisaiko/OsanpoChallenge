import SwiftUI

@main
struct OsanpoChallengeApp: App {
    @State private var walkData = WalkDataStore()
    @State private var walkSessions = WalkSessionStore()
    @State private var challenges = ChallengeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(walkData)
                .environment(walkSessions)
                .environment(challenges)
        }
    }
}

/// 端末に保存する設定のキー
enum StorageKey {
    static let healthConnected = "healthConnected"
    static let weeklyStepGoal = "weeklyStepGoal"
    static let dailyStepGoal = "dailyStepGoal"
}
