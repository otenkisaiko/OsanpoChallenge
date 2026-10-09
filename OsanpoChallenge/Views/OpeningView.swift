import SwiftUI

/// 初回起動時のオープニング画面
struct OpeningView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 空と風景
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                Image("opening_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
                Text("お散歩チャレンジ")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color.navy)
                    .padding(.top, 4)
                Text("歩くたびに、\n新しい景色に出会う。")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.navy)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .tracking(2)
                    .padding(.top, 20)
                Spacer(minLength: 16)
                Image("opening_landscape")
                    .resizable()
                    .scaledToFit()
            }
            .frame(maxWidth: .infinity)
            .background(Color.skyBottom)

            // ボタン
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
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 12)
        }
        .background(.white)
    }
}

#Preview {
    OpeningView(onStart: {})
}
