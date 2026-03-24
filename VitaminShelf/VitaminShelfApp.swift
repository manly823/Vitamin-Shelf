import SwiftUI

@main
struct VitaminShelfApp: App {
    @StateObject private var manager = ShelfManager()
    var body: some Scene {
        WindowGroup {
            Group {
                if manager.onboardingDone { MainView() } else { OnboardingView() }
            }
            .environmentObject(manager)
            .preferredColorScheme(.dark)
        }
    }
}
