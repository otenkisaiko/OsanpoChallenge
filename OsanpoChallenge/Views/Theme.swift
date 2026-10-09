import SwiftUI

extension Color {
    /// 朱色（歩いた道・到着した宿場）
    static let shu = Color(red: 0.85, green: 0.28, blue: 0.14)
    /// 藍色
    static let ai = Color(red: 0.16, green: 0.27, blue: 0.47)
    /// 和紙色（仮マップの背景）
    static let washi = Color(red: 0.96, green: 0.93, blue: 0.86)
    /// 墨色（マップ上の文字）
    static let sumi = Color(red: 0.2, green: 0.18, blue: 0.16)

    // モックアップ（0930_image.png）の配色
    /// メインの紺色（ボタン・見出し）
    static let navy = Color(hex: 0x1B5A8C)
    /// 空の色（オープニングの背景）
    static let skyTop = Color(hex: 0xDDF5FF)
    static let skyBottom = Color(hex: 0xC5ECFD)
    /// 歩数の進捗バー
    static let walkGreen = Color(hex: 0x4BB18A)
    /// マップ画面の背景（空色）
    static let mapSky = Color(hex: 0xD8F1FD)
    /// 淡い青のカード
    static let paleBlue = Color(hex: 0xE5F4FE)
    /// 宿場一覧のタイムラインの線
    static let timelineBlue = Color(hex: 0xC2E4F6)
    /// 現在地・宿場番号の青
    static let stationBlue = Color(hex: 0x4F95CD)
    /// 地図の道の点線（route_53.ai の道と同じ水色）
    static let routeDash = Color(red: 0.345, green: 0.784, blue: 0.957)
    /// 地図の歩いた道
    static let walkedRoute = Color(hex: 0x2F7FD1)
    /// 「チャレンジ中」の赤
    static let challengeRed = Color(hex: 0xE0453A)

    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension Double {
    /// 「12.3」のような km 表示
    var kmText: String {
        formatted(.number.precision(.fractionLength(1)))
    }
}

/// 角丸のカード
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }

    /// スクロールした中身が時計の下に重ならないよう、画面上部の帯を背景色で覆う
    func statusBarBackground(_ color: Color) -> some View {
        overlay(alignment: .top) {
            GeometryReader { geo in
                color
                    .frame(height: geo.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(false)
        }
    }
}
