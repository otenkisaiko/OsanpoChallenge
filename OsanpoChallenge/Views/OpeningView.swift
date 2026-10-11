import SwiftUI

/// 起動時のオープニング画面。イラストを画面いっぱいに敷き、空の部分にロゴと文字を置く
struct OpeningView: View {
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geo.size.height * 0.1)
                Image("opening_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(geo.size.width * 0.46, 220))
                Text("お散歩チャレンジ")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color.navy)
                    .padding(.top, 14)
                Text("歩くたびに、\n新しい景色に出会う。")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.navy)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .tracking(2)
                    .padding(.top, 18)
                Spacer()
                startButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .background {
            // 空の色で下地を作り、その上にイラストを下寄せで敷く（縦横比が違う端末でも山と町が見えるように）
            Color(hex: 0x77CAFC)
                .overlay(alignment: .bottom) {
                    Image("opening_background")
                        .resizable()
                        .scaledToFill()
                }
                .ignoresSafeArea()
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack {
                Spacer()
                Text("はじめる")
                    .font(.headline)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(Color.navy, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
    }
}

#Preview {
    OpeningView(onStart: {})
}
