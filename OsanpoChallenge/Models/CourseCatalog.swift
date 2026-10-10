import SwiftUI

/// ホーム画面の「チャレンジを選ぶ」とコース詳細に表示するコース情報
struct CourseSummary: Identifiable, Hashable {
    let id: String
    let title: String
    /// 一覧カードの短い説明
    let catchphrase: String
    /// 詳細画面の見出し上の小さなラベル
    let category: String
    /// 詳細画面の説明文
    let description: String
    let distanceKm: Double
    let difficulty: String
    let imageName: String
    let heroImageName: String
    let cardColor: Color
    /// 詳細画面の見出し・ボタンの色
    let themeColor: Color
    /// 「主な宿場町」のチップ（空なら表示しない）
    let highlightPlaces: [String]
    /// 「見どころ」のリスト（空なら表示しない）
    let highlights: [Highlight]
    /// 遊べるコースか（false なら「準備中」）
    let isAvailable: Bool

    struct Highlight: Hashable {
        let symbol: String
        let text: String
    }

    /// 目安日数の計算に使う、1日に歩く距離（1万歩 ≒ 7km）
    static let dailyPaceKm = 7.0

    /// 「495」「1,069」、短いコースは「34.5」
    var distanceText: String {
        distanceKm < 100 ? distanceKm.kmText : Int(distanceKm.rounded()).formatted()
    }

    /// 1日1万歩で歩いた場合の日数（5日単位に丸める）
    var estimatedDays: Int {
        max(5, Int((distanceKm / Self.dailyPaceKm / 5).rounded()) * 5)
    }
}

extension Course {
    /// 遊べるコース（地図と宿場のデータがあるもの）
    static let playable: [Course] = [.tokaido, .ohenro, .yamanote]

    static func find(_ id: String) -> Course? {
        playable.first { $0.id == id }
    }

    /// ホームやカードに出すコース情報（画像・色など）
    var summary: CourseSummary? {
        CourseCatalog.all.first { $0.id == id }
    }
}

enum CourseCatalog {
    static let all: [CourseSummary] = [
        CourseSummary(
            id: Course.tokaido.id,
            title: Course.tokaido.title,
            catchphrase: "江戸から京都へ、\n歴史の道を歩く",
            category: "日本の歴史をたどる",
            description: "江戸から京都まで、東海道の宿場町をめぐる歴史と風景の旅。昔の人たちと同じ道を歩いて、日本の原風景を感じてみませんか。",
            distanceKm: Course.tokaido.totalDistance,
            difficulty: "やや高め",
            imageName: "course_tokaido",
            heroImageName: "course_tokaido",
            cardColor: Color(hex: 0xD8EFFE),
            themeColor: .navy,
            highlightPlaces: ["日本橋（東京）", "品川", "藤枝", "掛川", "浜松", "吉田（豊橋）", "岡崎", "三条大橋（京都）"],
            highlights: [],
            isAvailable: true
        ),
        CourseSummary(
            id: Course.ohenro.id,
            title: Course.ohenro.title,
            catchphrase: "八十八ヶ所をめぐる\n心の旅",
            category: "心を整える旅",
            description: "徳島・高知・愛媛・香川の四国4県にある、弘法大師ゆかりの八十八ヶ所をめぐる心の旅。1番 霊山寺から88番 大窪寺まで歩きとおすと「結願」です。美しい自然と、あたたかい人々との出会いがあなたを待っています。",
            distanceKm: Course.ohenro.totalDistance,
            difficulty: "高め",
            imageName: "course_ohenro",
            heroImageName: "course_ohenro",
            cardColor: Color(hex: 0xE7E5FC),
            themeColor: Color(hex: 0x5B4A9E),
            highlightPlaces: [],
            highlights: [
                .init(symbol: "building.columns.fill", text: "八十八ヶ所の寺院めぐり"),
                .init(symbol: "mountain.2.fill", text: "四季折々の自然"),
                .init(symbol: "face.smiling.inverse", text: "地域の人とのふれあい"),
            ],
            isAvailable: true
        ),
        CourseSummary(
            id: Course.yamanote.id,
            title: Course.yamanote.title,
            catchphrase: "東京の街を、\nぐるっと30駅めぐり",
            category: "東京の街歩き",
            description: "東京駅から外回りで、山手線の30駅をぐるっと一周。銀座、渋谷、新宿、池袋、上野……。東京のいろいろな街の顔を、自分の足でつないでいきましょう。はじめてのチャレンジにもおすすめです。",
            distanceKm: Course.yamanote.totalDistance,
            difficulty: "やさしい",
            imageName: "course_yamanote",
            heroImageName: "course_yamanote",
            cardColor: Color(hex: 0xE6F4D8),
            themeColor: Color(hex: 0x3E8E2E),
            highlightPlaces: ["東京", "品川", "渋谷", "新宿", "池袋", "上野", "秋葉原"],
            highlights: [],
            isAvailable: true
        ),
        CourseSummary(
            id: "route1",
            title: "国道1号 日本橋〜大阪",
            catchphrase: "日本の大動脈を歩く\nロングチャレンジ",
            category: "ロングチャレンジ",
            description: "東京・日本橋から大阪・梅田新道まで、日本の大動脈「国道1号」を自分の足で。大きな街から小さな町まで、移り変わる景色を楽しみましょう。",
            // 日本橋〜梅田新道を1本の道としてたどった長さ（約566.4km）。
            // Wikipedia の総延長 764.6km は、並行するバイパスと旧道を合算した値なので使わない
            distanceKm: 566.4,
            difficulty: "やや高め",
            imageName: "course_route1",
            heroImageName: "course_route1",
            cardColor: Color(hex: 0xE5F6F2),
            themeColor: Color(hex: 0x2E7D6B),
            highlightPlaces: [],
            highlights: [],
            isAvailable: false
        ),
        CourseSummary(
            id: "basho",
            title: "奥の細道",
            catchphrase: "俳句の旅をたどる",
            category: "文学の旅",
            description: "俳聖・松尾芭蕉が歩いた道をたどる旅。名句が生まれた土地の風景に、思いをはせてみませんか。",
            distanceKm: 2400,
            difficulty: "高め",
            imageName: "course_basho",
            heroImageName: "course_basho",
            cardColor: Color(hex: 0xFCF6E6),
            themeColor: Color(hex: 0x9A6B1F),
            highlightPlaces: [],
            highlights: [],
            isAvailable: false
        ),
    ]
}
