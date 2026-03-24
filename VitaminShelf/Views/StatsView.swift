import SwiftUI

struct StatsView: View {
    @EnvironmentObject var manager: ShelfManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                adherenceRing
                streakCard
                weeklyChart
                categoryChart
                mostMissedSection
                totalsRow
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        HStack {
            Text("Statistics").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var adherenceRing: some View {
        let rate7 = manager.adherenceRate(days: 7)
        let rate30 = manager.adherenceRate(days: 30)
        return HStack(spacing: 24) {
            VStack(spacing: 8) {
                ZStack {
                    ProgressRing(progress: rate7, color: Theme.accent, lineWidth: 12, size: 110)
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", rate7 * 100))
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
                        Text("7 days").font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.sub)
                    }
                }
                Text("This Week").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
            }
            VStack(spacing: 8) {
                ZStack {
                    ProgressRing(progress: rate30, color: Theme.secondary, lineWidth: 12, size: 110)
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", rate30 * 100))
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Theme.secondary)
                        Text("30 days").font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.sub)
                    }
                }
                Text("This Month").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
            }
        }
        .frame(maxWidth: .infinity)
        .glowCard()
    }

    private var streakCard: some View {
        let streak = manager.currentStreak()
        return HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28)).foregroundStyle(streak > 0 ? Theme.warm : Theme.muted)
                .frame(width: 50, height: 50)
                .background((streak > 0 ? Theme.warm : Theme.muted).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak) day streak")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text(streak > 0 ? "Keep it going!" : "Take all your supplements today to start a streak")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
        }
        .glowCard()
    }

    private var weeklyChart: some View {
        let data = manager.weeklyAdherence()
        let maxVal: Double = 100
        return VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Adherence").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { point in
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", point.value))
                            .font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LinearGradient(
                                colors: [barColor(point.value), barColor(point.value).opacity(0.3)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: max(CGFloat(point.value / maxVal) * 100, 4))
                        Text(point.label).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .glowCard()
    }

    private func barColor(_ value: Double) -> Color {
        if value >= 90 { return Theme.success }
        if value >= 50 { return Theme.warm }
        return Theme.danger
    }

    private var categoryChart: some View {
        let data = manager.categoryBreakdown()
        return VStack(alignment: .leading, spacing: 12) {
            Text("By Category").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            if data.isEmpty {
                emptyPlaceholder("No active supplements")
            } else {
                let maxVal = max(data.map(\.value).max() ?? 1, 1)
                ForEach(data) { point in
                    HStack(spacing: 10) {
                        Text(point.label).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
                            .frame(width: 80, alignment: .leading)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(geo.size.width * CGFloat(point.value / maxVal), 4))
                        }
                        .frame(height: 14)
                        Text("\(Int(point.value))").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Theme.sub)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .glowCard()
    }

    private var mostMissedSection: some View {
        let missed = manager.mostMissedSups()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Most Missed").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.danger)
            if missed.isEmpty {
                emptyPlaceholder("No missed doses — great job!")
            } else {
                ForEach(missed, id: \.name) { item in
                    HStack(spacing: 10) {
                        Text(item.emoji).font(.system(size: 14))
                        Text(item.name).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
                        Spacer()
                        Text("\(item.count) missed").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Theme.danger)
                    }
                }
            }
        }
        .glowCard()
    }

    private var totalsRow: some View {
        HStack(spacing: 10) {
            totalTile("Total Taken", "\(manager.totalTaken())", Theme.success)
            totalTile("Total Missed", "\(manager.totalMissed())", Theme.danger)
            totalTile("Skipped", "\(manager.totalSkipped())", Theme.warm)
        }
    }

    private func totalTile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.system(size: 9, design: .rounded)).foregroundStyle(Theme.sub).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity).glowCard()
    }

    private func emptyPlaceholder(_ msg: String) -> some View {
        HStack {
            Spacer()
            Text(msg).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub).padding(.vertical, 14)
            Spacer()
        }
    }
}
