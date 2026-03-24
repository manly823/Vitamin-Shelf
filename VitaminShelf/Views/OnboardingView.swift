import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var manager: ShelfManager
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String, color: Color)] = [
        ("pills.fill", "Track Your Supplements",
         "Add all your vitamins and supplements. Vitamin Shelf comes pre-loaded with 20 popular options — just activate the ones you take.",
         Theme.accent),
        ("bell.fill", "Never Miss a Dose",
         "Get reminders at the right time. Mark doses as taken, skipped, or let the app track missed ones automatically.",
         Theme.info),
        ("chart.bar.fill", "See Your Progress",
         "Track your adherence with weekly charts, streaks, and detailed statistics. Know exactly how consistent you are.",
         Theme.secondary),
        ("shippingbox.fill", "Stock Alerts",
         "Track how many pills you have left. Get notified when stock is running low so you can reorder in time.",
         Theme.warm),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if page < pages.count { infoPage } else { readyPage }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var infoPage: some View {
        VStack(spacing: 30) {
            Spacer()
            let p = pages[page]
            Image(systemName: p.icon).font(.system(size: 52)).foregroundStyle(p.color)
                .frame(width: 120, height: 120)
                .background(p.color.opacity(0.1), in: Circle())
            VStack(spacing: 10) {
                Text(p.title).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text(p.body).font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.sub)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
            dots
            nextButton("Next") { withAnimation { page += 1 } }
            Spacer().frame(height: 30)
        }
    }

    private var readyPage: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.shield.fill").font(.system(size: 52)).foregroundStyle(Theme.success)
                .frame(width: 120, height: 120)
                .background(Theme.success.opacity(0.1), in: Circle())
            VStack(spacing: 10) {
                Text("All Set!").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text("Your shelf is pre-loaded with popular supplements. Activate the ones you take and start tracking today!")
                    .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.sub)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
            dots
            nextButton("Get Started") {
                NotificationHelper.shared.requestPermission()
                manager.onboardingDone = true
            }
            Spacer().frame(height: 30)
        }
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count + 1, id: \.self) { i in
                Circle().fill(i == page ? Theme.accent : Theme.muted).frame(width: 8, height: 8)
            }
        }
    }

    private func nextButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.bg).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 30)
    }
}
