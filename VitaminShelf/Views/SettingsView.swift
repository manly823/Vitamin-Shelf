import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ShelfManager
    @Environment(\.dismiss) var dismiss
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileSection
                    notificationSection
                    summarySection
                    dangerSection
                    appInfoSection
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.accent)
                }
            }
            .alert("Reset All Data?", isPresented: $showReset) {
                Button("Reset", role: .destructive) { manager.resetAllData(); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore the default supplement catalog and delete all intake history. This cannot be undone.")
            }
        }
    }

    private var profileSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "pills.fill").font(.system(size: 22)).foregroundStyle(Theme.accent)
                .frame(width: 50, height: 50)
                .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Vitamin Shelf").font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text("\(manager.activeSups.count) active supplements · \(manager.records.count) records")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
        }
        .glowCard()
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Button {
                NotificationHelper.shared.requestPermission { granted in
                    if granted { NotificationHelper.shared.scheduleAll(for: manager.supplements) }
                }
            } label: {
                HStack {
                    Image(systemName: "bell.fill").foregroundStyle(Theme.accent)
                    Text("Re-sync Reminders").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "arrow.clockwise").foregroundStyle(Theme.sub)
                }
            }
            Text("Reschedules all dose reminders based on current active supplements.")
                .font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.muted)
        }
        .glowCard()
    }

    private var summarySection: some View {
        VStack(spacing: 8) {
            dataRow("Active Supplements", "\(manager.activeSups.count)", Theme.success)
            dataRow("Inactive", "\(manager.inactiveSups.count)", Theme.muted)
            dataRow("Low Stock", "\(manager.lowStockSups.count)", Theme.warm)
            dataRow("Empty", "\(manager.emptySups.count)", Theme.danger)
            Divider().background(Theme.muted)
            dataRow("Total Records", "\(manager.records.count)", Theme.info)
            dataRow("Total Taken", "\(manager.totalTaken())", Theme.success)
            dataRow("Total Missed", "\(manager.totalMissed())", Theme.danger)
            dataRow("7-day Adherence", String(format: "%.0f%%", manager.adherenceRate(days: 7) * 100), Theme.accent)
        }
        .glowCard()
    }

    private func dataRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(color)
        }
    }

    private var dangerSection: some View {
        Button { showReset = true } label: {
            HStack {
                Image(systemName: "trash.fill").foregroundStyle(Theme.danger)
                Text("Reset All Data").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Theme.danger)
                Spacer()
            }
        }
        .glowCard()
    }

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            infoRow("Version", "1.0")
            infoRow("Data Storage", "Local Only")
            infoRow("Pre-loaded", "20 supplements")
            infoRow("Tracking", "None")
        }
        .glowCard()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).foregroundStyle(Theme.muted)
        }
        .font(.system(size: 13, design: .rounded))
    }
}
