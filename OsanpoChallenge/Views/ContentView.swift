import SwiftUI

enum MainTab {
    case home, map, challenge, myPage
}

struct ContentView: View {
    @Environment(WalkDataStore.self) private var walkData
    @Environment(WalkSessionStore.self) private var walkSessions
    @Environment(ChallengeStore.self) private var challenges
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StorageKey.healthConnected) private var healthConnected = false
    /// 起動するたびにオープニングから始める
    @State private var showingOpening = true
    @State private var arrivedStation: Station?
    @State private var selectedTab = MainTab.home

    /// 今チャレンジ中のコース
    private var activeCourse: Course? {
        challenges.activeCourseID.flatMap(Course.find)
    }

    private var progress: JourneyProgress? {
        guard let course = activeCourse, let challenge = challenges.activeChallenge else { return nil }
        // お散歩中の分も含めて、このコースをはじめてからのお散歩を数える
        let walks = walkSessions.sessions(for: course.id, since: challenge.startDate)
            .map { DailyWalk(date: $0.end ?? .now, km: $0.km) }
        return JourneyProgress(course: course, daily: walks, extraKm: challenge.debugExtraKm,
                               startDate: challenge.startDate)
    }

    var body: some View {
        Group {
            if showingOpening {
                OpeningView {
                    withAnimation { showingOpening = false }
                    if !healthConnected {
                        Task { await connectHealth() }
                    }
                }
                .transition(.opacity)
            } else {
                mainTabs
            }
        }
        .preferredColorScheme(.light)
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
        }
        .onChange(of: progress?.currentStation.id) { checkArrival() }
        .sheet(item: $arrivedStation) { station in
            if let progress {
                ArrivalView(station: station, progress: progress)
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            ChallengeHomeView(onStart: startChallenge)
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(MainTab.home)
            Group {
                if let course = activeCourse, let progress {
                    JourneyView(course: course, progress: progress, onConnect: connectHealth)
                } else {
                    NoChallengeView { selectedTab = .home }
                }
            }
            .tabItem { Label("マップ", systemImage: "map") }
            .tag(MainTab.map)
            Group {
                if let progress {
                    StationListView(progress: progress)
                } else {
                    NoChallengeView { selectedTab = .home }
                }
            }
            .tabItem { Label("チャレンジ", systemImage: "trophy") }
            .tag(MainTab.challenge)
            SettingsView()
                .tabItem { Label("マイページ", systemImage: "person") }
                .tag(MainTab.myPage)
        }
    }

    /// コース詳細の「チャレンジをはじめる / 再開する」
    private func startChallenge(_ summary: CourseSummary) {
        guard summary.isAvailable else { return }
        challenges.startOrResume(summary.id)
        selectedTab = .map
    }

    private func connectHealth() async {
        await walkData.requestAuthorization()
        healthConnected = true
        await reload()
    }

    private func reload() async {
        checkArrival()
        guard healthConnected else { return }
        await walkData.refresh()
    }

    /// 新しい宿場に着いていたらお祝い画面を出す
    private func checkArrival() {
        guard let progress, let challenge = challenges.activeChallenge else { return }
        let current = progress.currentStation
        if current.id > challenge.lastCelebratedStationID {
            arrivedStation = current
            challenges.updateActive { $0.lastCelebratedStationID = current.id }
        } else if current.id < challenge.lastCelebratedStationID {
            challenges.updateActive { $0.lastCelebratedStationID = current.id }
        }
    }
}

/// チャレンジ中のコースがないときの「マップ」「チャレンジ」タブ
private struct NoChallengeView: View {
    let onChooseCourse: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 44))
                .foregroundStyle(Color.navy.opacity(0.6))
            Text("チャレンジ中のコースはありません")
                .font(.headline)
                .foregroundStyle(Color.navy)
            Text("ホームでコースを選んで、\nチャレンジをはじめましょう。")
                .font(.subheadline)
                .foregroundStyle(Color.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            Button(action: onChooseCourse) {
                Text("コースを選ぶ")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.navy, in: Capsule())
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mapSky.ignoresSafeArea())
    }
}
