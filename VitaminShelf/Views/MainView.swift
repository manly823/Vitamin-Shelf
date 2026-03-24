import SwiftUI

struct MainView: View {
    @EnvironmentObject var manager: ShelfManager
    @State private var selectedTab = 0
    @State private var showSettings = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.05, blue: 0.12, alpha: 1)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            todayTab
            shelfTab
            logTab
            statsTab
        }
        .tint(Theme.accent)
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var todayTab: some View {
        NavigationStack {
            TodayView()
                .navigationTitle("")
                .toolbar { settingsButton }
                .background(Theme.bg.ignoresSafeArea())
        }
        .tabItem { Label("Today", systemImage: "sun.max.fill") }
        .tag(0)
    }

    private var shelfTab: some View {
        NavigationStack {
            ShelfView()
                .navigationTitle("")
                .toolbar { settingsButton }
                .background(Theme.bg.ignoresSafeArea())
        }
        .tabItem { Label("Shelf", systemImage: "cabinet.fill") }
        .tag(1)
    }

    private var logTab: some View {
        NavigationStack {
            LogView()
                .navigationTitle("")
                .toolbar { settingsButton }
                .background(Theme.bg.ignoresSafeArea())
        }
        .tabItem { Label("Log", systemImage: "calendar") }
        .tag(2)
    }

    private var statsTab: some View {
        NavigationStack {
            StatsView()
                .navigationTitle("")
                .toolbar { settingsButton }
                .background(Theme.bg.ignoresSafeArea())
        }
        .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        .tag(3)
    }

    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 15)).foregroundStyle(Theme.sub)
                    .frame(width: 34, height: 34).background(Theme.surface, in: Circle())
            }
        }
    }
}
