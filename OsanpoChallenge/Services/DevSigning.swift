#if DEBUG
import Foundation

/// 開発中だけ使う：無料の Apple ID で入れたアプリの有効期限（7日間）を読む。
/// アプリに同梱された embedded.mobileprovision の ExpirationDate を取り出す
enum DevSigning {
    static let expirationDate: Date? = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .isoLatin1),
              let keyRange = text.range(of: "<key>ExpirationDate</key>"),
              let start = text.range(of: "<date>", range: keyRange.upperBound..<text.endIndex),
              let end = text.range(of: "</date>", range: start.upperBound..<text.endIndex)
        else { return nil }
        return ISO8601DateFormatter().date(from: String(text[start.upperBound..<end.lowerBound]))
    }()

    /// 期限まで2日を切ったら true
    static var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        return expirationDate.timeIntervalSinceNow < 2 * 24 * 60 * 60
    }
}
#endif
