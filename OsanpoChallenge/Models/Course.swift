import CoreGraphics

/// チェックポイント（宿場・札所など）
struct Station: Identifiable, Hashable {
    let id: Int
    /// 「品川」のような短い名前
    let shortName: String
    /// 「品川宿」のような表示名
    let name: String
    /// ひとつ前のチェックポイントからの距離（km）
    let distanceFromPrevious: Double
    /// 起点からの距離（km）
    let cumulativeDistance: Double
    let isStart: Bool
    let isGoal: Bool
    /// 一覧の丸に出す番号（起点・終点など番号がないものは nil）
    let number: Int?
    /// 「起点」「第1宿」「第1番札所」
    let label: String
}

/// チェックポイントの呼び方（コースごとに違う言葉）
enum CheckpointStyle {
    /// 東海道などの宿場（日本橋を起点に「第1宿」…「終点」）
    case shukuba
    /// お遍路の札所（1番から「第1番札所」…）
    case fudasho
    /// 鉄道の駅（山手線など。起点に戻ってくる一周のコース）
    case eki

    /// 「宿場」「札所」
    var noun: String {
        switch self {
        case .shukuba: "宿場"
        case .fudasho: "札所"
        case .eki: "駅"
        }
    }

    /// 札所一覧などの画面名
    var listTitle: String { "\(noun)一覧" }

    /// スタンプを集める帳面の名前
    var bookTitle: String {
        switch self {
        case .shukuba: "宿場帳"
        case .fudasho: "納経帳"
        case .eki: "駅スタンプ帳"
        }
    }

    /// 到着したときのスタンプの文字
    var arrivalStamp: String {
        switch self {
        case .shukuba: "到着"
        case .fudasho: "参拝"
        case .eki: "到着"
        }
    }

    /// ゴールのスタンプの文字
    var goalStamp: String {
        switch self {
        case .shukuba: "踏破"
        case .fudasho: "結願"
        case .eki: "一周"
        }
    }

    /// 到着画面の「〇〇宿」の下の文
    var arrivedMessage: String {
        switch self {
        case .shukuba: "に到着しました！"
        case .fudasho: "を参拝しました！"
        case .eki: "に到着しました！"
        }
    }

    /// 起点にも到着スタンプを押すか（お遍路は1番札所から参拝する）
    var stampsStart: Bool { self == .fudasho }

    /// 到着日の言い方（「◯月◯日に到着」）
    func arrivalVerb(for station: Station) -> String {
        if station.isStart && !stampsStart { return "出発" }
        return self == .fudasho ? "参拝" : "到着"
    }

    /// 宿場詳細の見出し「15.蒲原宿」「起点 日本橋」「1番 霊山寺」
    func numberedName(for station: Station) -> String {
        switch self {
        case .shukuba:
            if station.isStart { return "起点 \(station.name)" }
            if station.isGoal { return "終点 \(station.name)" }
            return "\(station.id).\(station.name)"
        case .fudasho:
            return "\(station.number ?? station.id + 1)番 \(station.name)"
        case .eki:
            if station.isStart { return "出発 \(station.name)" }
            if station.isGoal { return "一周 \(station.name)" }
            return "\(station.id).\(station.name)"
        }
    }
}

/// ひとつの旅のコース
struct Course {
    let id: String
    let title: String
    let style: CheckpointStyle
    let stations: [Station]
    /// マップ画像（イラスト）の座標系のサイズ
    let mapSize: CGSize
    /// Assets に入れたマップ画像の名前。nil なら仮の背景を描く
    let mapImageName: String?
    /// マップ上の道のり（mapSize の座標系）
    let route: [CGPoint]
    /// 各チェックポイントが道のり全体のどこにあるか（0〜1）
    let stationPathFractions: [Double]
    /// マップ左上の小さな説明（「全 53 宿」「八十八ヶ所」）
    let badgeText: String

    var totalDistance: Double { stations.last?.cumulativeDistance ?? 0 }

    /// 起点に戻ってくる一周のコースか（山手線など）
    var isLoop: Bool { stations.count > 1 && stations.first?.shortName == stations.last?.shortName }

    /// 宿場のコース
    /// - Parameters:
    ///   - segments: 起点の次から終点までの（名前, 前からの距離km）。終点以外は名前に「宿」を付ける
    ///   - stationPathFractions: イラスト上の各地点の位置。省略すると距離に比例して配置する
    init(
        id: String,
        title: String,
        startName: String,
        segments: [(name: String, km: Double)],
        badgeText: String,
        mapSize: CGSize,
        mapImageName: String?,
        route: [CGPoint],
        stationPathFractions: [Double]? = nil
    ) {
        let last = segments.count
        var checkpoints = [(shortName: startName, name: startName, km: 0.0)]
        for (index, segment) in segments.enumerated() {
            let isGoal = index + 1 == last
            checkpoints.append((segment.name, isGoal ? segment.name : segment.name + "宿", segment.km))
        }
        self.init(id: id, title: title, style: .shukuba, checkpoints: checkpoints, badgeText: badgeText,
                  mapSize: mapSize, mapImageName: mapImageName, route: route,
                  stationPathFractions: stationPathFractions)
    }

    /// - Parameter checkpoints: 起点から終点までの（短い名前, 表示名, 前からの距離km）。起点の距離は 0
    init(
        id: String,
        title: String,
        style: CheckpointStyle,
        checkpoints: [(shortName: String, name: String, km: Double)],
        badgeText: String,
        mapSize: CGSize,
        mapImageName: String?,
        route: [CGPoint],
        stationPathFractions: [Double]? = nil
    ) {
        var stations: [Station] = []
        var total = 0.0
        for (index, point) in checkpoints.enumerated() {
            let isStart = index == 0
            let isGoal = index == checkpoints.count - 1
            total += isStart ? 0 : point.km
            let number: Int?
            let label: String
            switch style {
            case .shukuba:
                number = isStart || isGoal ? nil : index
                label = isStart ? "起点" : (isGoal ? "終点" : "第\(index)宿")
            case .fudasho:
                number = index + 1
                label = "第\(index + 1)番札所"
            case .eki:
                number = isStart || isGoal ? nil : index
                label = isStart ? "出発" : (isGoal ? "一周" : "\(index)駅目")
            }
            stations.append(Station(
                id: index,
                shortName: point.shortName,
                name: point.name,
                distanceFromPrevious: isStart ? 0 : point.km,
                cumulativeDistance: total,
                isStart: isStart,
                isGoal: isGoal,
                number: number,
                label: label
            ))
        }
        self.id = id
        self.title = title
        self.style = style
        self.stations = stations
        self.badgeText = badgeText
        self.mapSize = mapSize
        self.mapImageName = mapImageName
        self.route = route
        self.stationPathFractions = stationPathFractions
            ?? stations.map { total > 0 ? $0.cumulativeDistance / total : 0 }
    }

    /// 歩いた距離（km）が、マップ上の道のりのどこ（0〜1）にあたるか
    func pathFraction(forDistance km: Double) -> Double {
        let d = min(max(km, 0), totalDistance)
        guard let i = stations.lastIndex(where: { $0.cumulativeDistance <= d }) else { return 0 }
        guard i + 1 < stations.count else { return 1 }
        let next = stations[i + 1]
        let t = next.distanceFromPrevious > 0 ? (d - stations[i].cumulativeDistance) / next.distanceFromPrevious : 0
        return stationPathFractions[i] + (stationPathFractions[i + 1] - stationPathFractions[i]) * t
    }
}
