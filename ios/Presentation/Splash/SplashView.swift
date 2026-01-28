import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.lg) {
                Image("LogoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("Cookstemma")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }
}

#Preview {
    SplashView()
}
