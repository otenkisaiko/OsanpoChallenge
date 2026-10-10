import Foundation

/// 宿場詳細に出す読み方と解説
struct StationGuide {
    /// 「しながわしゅく」のような読み方
    let reading: String
    /// 解説（段落は空行で区切る）
    let description: String
    /// 参考にした Wikipedia の記事名
    let wikipediaTitle: String

    var wikipediaURL: URL? {
        URL(string: "https://ja.wikipedia.org/wiki/" + wikipediaTitle.replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
    }
}

extension Course {
    /// チェックポイントの解説（ない場合は nil）
    func guide(for station: Station) -> StationGuide? {
        let guides: [StationGuide]
        switch id {
        case Course.tokaido.id: guides = TokaidoGuide.all
        case Course.ohenro.id: guides = OhenroGuide.all
        case Course.yamanote.id: guides = YamanoteGuide.all
        default: return nil
        }
        return station.id < guides.count ? guides[station.id] : nil
    }

    /// チェックポイントのイラスト名（Assets の画像名）
    func imageName(for station: Station) -> String {
        // 一周のコースのゴールは起点と同じ場所なので、起点の絵を使う
        let index = isLoop && station.isGoal ? 0 : station.id
        return String(format: "%@_station_%02d", id, index)
    }
}

/// 東海道五十三次の解説。
/// Wikipedia（日本語版）の各記事を参考に、内容を短くまとめ直したもの（本文の転載ではない）
enum TokaidoGuide {
    static let all: [StationGuide] = [
        StationGuide(
            reading: "にほんばし",
            description: """
            1603年、徳川家康による江戸の町づくりのなかで最初に架けられた橋。翌年には五街道の起点と定められ、全国へ向かう道のりはここから測られるようになりました。

            現在の橋は1911年（明治44年）に完成した石造りの二連アーチ橋で、国の重要文化財に指定されています。
            """,
            wikipediaTitle: "日本橋 (東京都中央区の橋)"),
        StationGuide(
            reading: "しながわしゅく",
            description: """
            東海道で最初の宿場で、1601年に港町・品川湊のそばに置かれました。中山道の板橋宿などとともに「江戸四宿」と呼ばれ、なかでもいちばん栄えた宿場です。

            西へ旅立つ人を見送り、江戸へ入る人を迎える玄関口として旅籠が立ち並び、大名行列の往来もさかんでした。
            """,
            wikipediaTitle: "品川宿"),
        StationGuide(
            reading: "かわさきしゅく",
            description: """
            品川と神奈川の間が離れていたため、1623年に後から加えられた宿場です。設置当初は負担が重く、宿場の経営に苦しんだ時期もありました。

            名主・本陣を務めた田中休愚が、多摩川の「六郷の渡し」の権利を宿場のものにするなどして、立て直しに力を尽くしました。
            """,
            wikipediaTitle: "川崎宿"),
        StationGuide(
            reading: "かながわしゅく",
            description: """
            神奈川湊のそばに置かれた宿場で、海と陸の人や物資が行き交う拠点として栄えました。

            高台の「台町」から見下ろす海の眺めは名所として知られ、広重の浮世絵や『東海道中膝栗毛』にも登場します。幕末には開港場に指定されました。
            """,
            wikipediaTitle: "神奈川宿"),
        StationGuide(
            reading: "ほどがやしゅく",
            description: """
            1601年に置かれた、武蔵国でいちばん西の宿場です。

            宿場を出るとすぐに上り坂の「権太坂」が待ちかまえ、旅人にとって最初の難所でした。江戸時代後期には旅籠が60軒以上あったと記録されています。
            """,
            wikipediaTitle: "保土ヶ谷宿"),
        StationGuide(
            reading: "とつかしゅく",
            description: """
            日本橋を朝に出た旅人が、ちょうど一泊目を迎えるあたりにある宿場です。そのため旅籠が多く、その数は小田原宿に次ぐ規模でした。

            大山道や鎌倉街道が交わる交通の要所で、品濃町には当時の一里塚が今も残っています。
            """,
            wikipediaTitle: "戸塚宿"),
        StationGuide(
            reading: "ふじさわしゅく",
            description: """
            時宗の総本山・遊行寺（清浄光寺）の門前町として、宿場ができる前から栄えていました。

            江の島へ向かう「江の島道」の入口でもあり、参詣の人々でにぎわいました。幕末には70軒を超える旅籠があったといいます。
            """,
            wikipediaTitle: "藤沢宿"),
        StationGuide(
            reading: "ひらつかしゅく",
            description: """
            相模川を渡った先にある宿場で、現在の神奈川県平塚市にあたります。

            宿場の西には、こんもりとした高麗山が見え、広重の浮世絵にも街道とともに描かれています。
            """,
            wikipediaTitle: "平塚宿"),
        StationGuide(
            reading: "おおいそしゅく",
            description: """
            相模湾に面した宿場で、現在の神奈川県大磯町にあたります。

            曾我兄弟の物語にちなむ「虎御石」や、西行の歌にゆかりのある「鴫立庵」など、物語や和歌にまつわる名所が残ります。
            """,
            wikipediaTitle: "大磯宿"),
        StationGuide(
            reading: "おだわらしゅく",
            description: """
            江戸を出て最初の城下町にある宿場です。箱根越えを控えた旅人が、ここで体を休めました。

            名物の「ういろう」やかまぼこは、今も町の名物として親しまれています。
            """,
            wikipediaTitle: "小田原宿"),
        StationGuide(
            reading: "はこねしゅく",
            description: """
            1618年、箱根峠と箱根関所の間に新しく設けられた宿場です。最初の住民は、小田原と三島から移り住んだ人々だったといわれます。

            標高約725mと五十三次でもっとも高い所にあり、「箱根八里」の険しい山道の途中で旅人を迎えました。
            """,
            wikipediaTitle: "箱根宿"),
        StationGuide(
            reading: "みしましゅく",
            description: """
            箱根を下りて最初の宿場で、三嶋大社の門前町としてにぎわいました。

            これから箱根を越える旅人と、越えてきた旅人の両方が泊まる宿場で、1843年の記録では旅籠が70軒あまりありました。
            """,
            wikipediaTitle: "三島宿"),
        StationGuide(
            reading: "ぬまづしゅく",
            description: """
            現在の静岡県沼津市大手町のあたりにあった宿場で、沼津城の城下町でもありました。

            1843年の記録では、本陣3軒、旅籠55軒を数えています。
            """,
            wikipediaTitle: "沼津宿"),
        StationGuide(
            reading: "はらしゅく",
            description: """
            かつて「浮島ヶ原」と呼ばれた湿地のそばの宿場で、源義経が大規模な馬揃えをした地として知られます。

            富士山を間近に望む景色が美しく、広重の浮世絵にも画面からはみ出すほど大きな富士が描かれています。
            """,
            wikipediaTitle: "原宿 (東海道)"),
        StationGuide(
            reading: "よしわらしゅく",
            description: """
            高潮の被害で、二度も場所を移した宿場です。

            移転によって街道が内陸へ大きく曲がったため、ふだんは右手に見える富士山が左手に見える「左富士」の名所が生まれました。
            """,
            wikipediaTitle: "吉原宿"),
        StationGuide(
            reading: "かんばらしゅく",
            description: """
            富士川を渡って最初の宿場です。

            雪の少ない土地なのに、広重の浮世絵「蒲原 夜之雪」では雪景色で描かれ、ひとつの謎とされています。『東海道中膝栗毛』の舞台としても登場します。
            """,
            wikipediaTitle: "蒲原宿"),
        StationGuide(
            reading: "ゆいしゅく",
            description: """
            駿河湾に面した宿場で、本陣の跡は「由比本陣公園」として整えられています。

            この先には、海と富士山を見渡す景勝地・薩埵峠があり、旅人はここでひと息ついてから峠越えにのぞみました。
            """,
            wikipediaTitle: "由比宿"),
        StationGuide(
            reading: "おきつしゅく",
            description: """
            古くから「清見潟」と呼ばれた景勝地にあり、和歌にも詠まれてきた宿場です。甲州へ向かう道との分かれ道でもありました。

            明治以降は気候のよさから、西園寺公望の別荘「坐漁荘」などが建てられ、保養地として知られました。
            """,
            wikipediaTitle: "興津"),
        StationGuide(
            reading: "えじりしゅく",
            description: """
            巴川の河口に発達した宿場で、清水港に近く、江戸への物流の拠点でもありました。

            清水次郎長ゆかりの地としても知られ、名物の「追分羊羹」は今も受け継がれています。
            """,
            wikipediaTitle: "江尻宿"),
        StationGuide(
            reading: "ふちゅうしゅく",
            description: """
            徳川家康が晩年を過ごした駿府城の城下にあった宿場で、現在の静岡市の中心部にあたります。

            安倍川のたもとでは名物の「安倍川餅」が売られ、『東海道中膝栗毛』にも登場します。
            """,
            wikipediaTitle: "府中宿 (東海道)"),
        StationGuide(
            reading: "まりこしゅく",
            description: """
            「丸子宿」とも書かれる、東海道でいちばん小さな宿場です。

            名物はとろろ汁で、松尾芭蕉も「梅若菜 丸子の宿の とろろ汁」と詠みました。1596年創業のとろろ汁の店「丁子屋」が、今も営業を続けています。
            """,
            wikipediaTitle: "鞠子宿"),
        StationGuide(
            reading: "おかべしゅく",
            description: """
            宇津ノ谷峠を越えた先にある宿場で、峠道や宇津ノ谷の集落には昔の町並みが残ります。

            1836年に再建された旅籠「柏屋」は国の登録有形文化財で、宿場の歴史を伝える施設として公開されています。
            """,
            wikipediaTitle: "岡部宿"),
        StationGuide(
            reading: "ふじえだしゅく",
            description: """
            田中城の城下町を兼ねた宿場で、相良へ向かう田沼街道の分かれ道でもありました。

            商いの町としても栄え、最盛期には37軒の旅籠があったといいます。
            """,
            wikipediaTitle: "藤枝宿"),
        StationGuide(
            reading: "しまだしゅく",
            description: """
            東海道一の難所・大井川の手前（江戸側）にある宿場です。

            「箱根八里は馬でも越すが 越すに越されぬ大井川」と歌われ、増水で川止めになると旅人が何日も足止めされ、宿場はおおいににぎわいました。川越しの遺跡は国の史跡です。
            """,
            wikipediaTitle: "島田宿"),
        StationGuide(
            reading: "かなやしゅく",
            description: """
            大井川を渡った京都側の宿場で、島田宿と対になる川越しの宿場です。川止めの日には、江戸へ向かう旅人で町があふれました。

            宿場の西には牧之原台地へ上る「金谷坂」があり、石畳の道が今も残っています。
            """,
            wikipediaTitle: "金谷宿"),
        StationGuide(
            reading: "にっさかしゅく",
            description: """
            東海道三大難所のひとつ「小夜の中山」の峠を下りたところにある、小さな宿場です。

            明治になって鉄道が峠を避けて敷かれたため町は静かになりましたが、そのぶん昔の宿場の雰囲気がよく残っています。
            """,
            wikipediaTitle: "日坂宿"),
        StationGuide(
            reading: "かけがわしゅく",
            description: """
            山内一豊が城主を務めた掛川城の城下町にある宿場です。

            海沿いの相良から信濃へ通じる「塩の道」（秋葉街道）が交わる場所で、秋葉山へ参詣する人々も行き交いました。
            """,
            wikipediaTitle: "掛川宿"),
        StationGuide(
            reading: "ふくろいしゅく",
            description: """
            江戸から数えても京から数えても27番目にあたる、五十三次のちょうど真ん中の宿場です。

            ほかの宿場より遅れて1616年までに整えられました。まわりには遠州三山などの古い寺社が多く、その門前町としても栄えました。
            """,
            wikipediaTitle: "袋井宿"),
        StationGuide(
            reading: "みつけしゅく",
            description: """
            古くは遠江国の国府が置かれた土地で、中世から大きな宿場町として栄えていました。

            天竜川の手前にあり、川止めのときには足止めされた旅人でにぎわいました。明治時代の「旧見付学校」の校舎が今も残っています。
            """,
            wikipediaTitle: "見附宿"),
        StationGuide(
            reading: "はままつしゅく",
            description: """
            浜松城の城下町にある宿場で、本陣が6軒、旅籠が90軒以上あった、遠江・駿河でいちばん大きな宿場です。

            距離のうえでも江戸と京のほぼ中間にあたり、東と西の境目の地域でした。
            """,
            wikipediaTitle: "浜松宿"),
        StationGuide(
            reading: "まいさかしゅく",
            description: """
            浜名湖の入口・今切口の東岸にある宿場です。

            ここから対岸の新居宿までは「今切の渡し」と呼ばれる船の旅でした。湖の口は、室町時代の大地震と津波によって開いたものと伝えられています。
            """,
            wikipediaTitle: "舞阪宿"),
        StationGuide(
            reading: "あらいしゅく",
            description: """
            今切の渡しを渡った西岸の宿場で、隣には旅人を厳しく取り調べた「新居関所（今切関所）」がありました。

            関所の建物が今も残る全国でただひとつの場所で、国の特別史跡に指定されています。
            """,
            wikipediaTitle: "新居宿"),
        StationGuide(
            reading: "しらすかしゅく",
            description: """
            遠江国のいちばん西にある宿場です。もとは海岸近くにありましたが、1707年の宝永地震の津波で被害を受け、潮見坂の上の高台へ移されました。

            潮見坂からは遠州灘を一望でき、旅人が海を眺める名所でした。
            """,
            wikipediaTitle: "白須賀宿"),
        StationGuide(
            reading: "ふたがわしゅく",
            description: """
            三河国のいちばん東の宿場で、現在の愛知県豊橋市にあたります。

            江戸時代の本陣の建物が今も残り、資料館として公開されている貴重な宿場です。
            """,
            wikipediaTitle: "二川宿"),
        StationGuide(
            reading: "よしだしゅく",
            description: """
            吉田城の城下町にある宿場で、現在の愛知県豊橋市の中心部にあたります。

            豊川に架かる吉田大橋は東海道でも有数の大きな橋で、宿場は多くの旅籠でにぎわいました。
            """,
            wikipediaTitle: "吉田宿 (東海道)"),
        StationGuide(
            reading: "ごゆしゅく",
            description: """
            浜名湖の北を回る「姫街道」の西の起点となる宿場です。

            隣の赤坂宿まではわずか約1.7kmで、その間に続く「御油の松並木」は国の天然記念物として、今も美しい姿を残しています。
            """,
            wikipediaTitle: "御油宿"),
        StationGuide(
            reading: "あかさかしゅく",
            description: """
            御油宿のすぐ隣にある宿場で、「御油や赤坂、吉田がなけりゃ…」と歌われるほどにぎわいました。

            1649年創業の旅籠「大橋屋」は、東海道で最後まで営業を続けた旅籠として知られ、2015年に宿泊の営業を終えました。
            """,
            wikipediaTitle: "赤坂宿 (東海道)"),
        StationGuide(
            reading: "ふじかわしゅく",
            description: """
            三河の山あいから平野へ出る入口にある宿場です。

            近くには約1kmの松並木が残り、国道1号沿いの「道の駅 藤川宿」でも宿場の歴史にふれられます。
            """,
            wikipediaTitle: "藤川宿"),
        StationGuide(
            reading: "おかざきしゅく",
            description: """
            徳川家康が生まれた岡崎城の城下町にある宿場で、府中宿に次ぐ大きさでした。

            矢作川に架かる矢作橋は、江戸時代の日本でいちばん長い橋として知られていました。
            """,
            wikipediaTitle: "岡崎宿"),
        StationGuide(
            reading: "ちりゅうしゅく",
            description: """
            現在の愛知県知立市にあった宿場です。

            毎年初夏には街道沿いの松並木で大きな馬市が開かれ、広重の浮世絵にも描かれました。三河の特産品だった木綿の市も立ちました。
            """,
            wikipediaTitle: "池鯉鮒宿"),
        StationGuide(
            reading: "なるみしゅく",
            description: """
            現在の名古屋市緑区にあった宿場で、お寺の多い町として知られます。

            近くの有松は、絞り染めの「有松・鳴海絞」で有名で、旅人のおみやげとして人気を集めました。
            """,
            wikipediaTitle: "鳴海宿"),
        StationGuide(
            reading: "みやしゅく",
            description: """
            熱田神宮の門前町・港町として栄えた、東海道でもっとも大きな宿場です。旅籠は200軒を超えていました。

            ここから桑名宿までは、東海道でただひとつの海の道「七里の渡し」を船で渡りました。
            """,
            wikipediaTitle: "宮宿"),
        StationGuide(
            reading: "くわなしゅく",
            description: """
            七里の渡しの西の船着き場にある宿場で、桑名藩の城下町でもありました。

            伊勢国の入口、お伊勢参りの玄関口としてにぎわい、名物の焼きはまぐりは「その手は桑名の焼きはまぐり」というしゃれ言葉にもなりました。
            """,
            wikipediaTitle: "桑名宿"),
        StationGuide(
            reading: "よっかいちしゅく",
            description: """
            幕府の直轄地で、代官所が置かれた宿場です。宮宿から直接船で渡る「十里の渡し」もありました。

            宿場の南の「日永の追分」は、伊勢神宮へ向かう伊勢街道との分かれ道です。名物の「なが餅」も知られています。
            """,
            wikipediaTitle: "四日市宿"),
        StationGuide(
            reading: "いしやくししゅく",
            description: """
            1616年に宿場となった、静かな宿場です。

            名前の由来となった石薬師寺があり、唱歌「夏は来ぬ」を作詞した歌人・佐佐木信綱が生まれた地としても知られています。
            """,
            wikipediaTitle: "石薬師宿"),
        StationGuide(
            reading: "しょうのしゅく",
            description: """
            現在の三重県鈴鹿市にあった、小さな宿場です。

            広重の浮世絵「庄野 白雨」は、にわか雨の中を急ぐ旅人を描いた五十三次の代表作のひとつです。旧小林家住宅が資料館として公開されています。
            """,
            wikipediaTitle: "庄野宿"),
        StationGuide(
            reading: "かめやましゅく",
            description: """
            亀山城の城下町を兼ねた宿場です。

            優美な姿から「胡蝶城」と呼ばれた亀山城には、多聞櫓が今も残っています。近くの野村一里塚は、三重県で唯一残る一里塚です。
            """,
            wikipediaTitle: "亀山宿"),
        StationGuide(
            reading: "せきじゅく",
            description: """
            古代の「鈴鹿関」が置かれた交通の要所で、伊勢別街道や大和街道との分かれ道でもありました。

            約1.8kmにわたって200棟以上の町家が残り、国の重要伝統的建造物群保存地区に選ばれています。東海道でもっとも昔の姿をとどめる宿場のひとつです。
            """,
            wikipediaTitle: "関宿"),
        StationGuide(
            reading: "さかしたしゅく",
            description: """
            難所・鈴鹿峠のふもとにある宿場です。

            峠越えの前後に泊まる旅人でにぎわい、鈴鹿馬子唄にも登場します。1650年の土石流で大きな被害を受け、現在の場所に移されました。
            """,
            wikipediaTitle: "坂下宿"),
        StationGuide(
            reading: "つちやましゅく",
            description: """
            鈴鹿峠を越えて近江国に入って最初の宿場です。

            「坂は照る照る 鈴鹿は曇る あいの土山雨が降る」と鈴鹿馬子唄に歌われました。1868年には、明治天皇が東京へ向かう途中にここで誕生日を迎えています。
            """,
            wikipediaTitle: "土山宿"),
        StationGuide(
            reading: "みなくちしゅく",
            description: """
            水口城の城下町を兼ねた宿場です。

            宿場の東側は道が三筋に分かれ、西側は城下町らしく鍵の手に曲がっていました。名物はかんぴょうで、広重の浮世絵にもかんぴょう作りが描かれています。
            """,
            wikipediaTitle: "水口宿"),
        StationGuide(
            reading: "いしべしゅく",
            description: """
            京都を出た旅人がちょうど一日目に泊まる場所で、「京立ち石部泊り」と言われました。

            1843年には本陣2軒と旅籠32軒があり、街道の両側に家並みが約1.6km続いていました。
            """,
            wikipediaTitle: "石部宿"),
        StationGuide(
            reading: "くさつしゅく",
            description: """
            東海道と中山道が合流する宿場です。

            江戸時代の本陣の建物が今も残り、国の史跡として公開されています。名物は「うばがもち」で、広重の浮世絵にも描かれています。
            """,
            wikipediaTitle: "草津宿"),
        StationGuide(
            reading: "おおつしゅく",
            description: """
            琵琶湖のほとりにある、東海道でも有数の大きな宿場です。

            京都との間の街道には、牛車が通りやすいように「車石」と呼ばれる石が敷かれていました。北国街道との分かれ道「札の辻」も残ります。
            """,
            wikipediaTitle: "大津宿"),
        StationGuide(
            reading: "さんじょうおおはし",
            description: """
            鴨川に架かる、東海道五十三次の終着点です。

            1589年に豊臣秀吉の命で石柱の橋に改修され、江戸時代には幕府が管理する公儀橋とされました。現在の橋は1950年の完成で、欄干の擬宝珠は古いものが大切に受け継がれています。
            """,
            wikipediaTitle: "三条大橋"),
    ]
}
