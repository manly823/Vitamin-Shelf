import SwiftUI

struct TodayView: View {
    @EnvironmentObject var manager: ShelfManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                progressSection
                if let next = manager.nextPending { nextDoseCard(next) }
                if !manager.lowStockSups.isEmpty { lowStockBanner }
                scheduleSection
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text(Date(), style: .date).font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var progressSection: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: manager.todayProgress, color: Theme.accent, lineWidth: 14, size: 120)
                VStack(spacing: 2) {
                    Text("\(manager.todayTaken)/\(manager.todayTotal)")
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
                    Text("taken").font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.sub)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                miniStat(icon: "checkmark.circle.fill", label: "Taken", value: "\(manager.todayTaken)", color: Theme.success)
                miniStat(icon: "circle", label: "Pending", value: "\(manager.todayRecords.filter { $0.status == .pending }.count)", color: Theme.sub)
                miniStat(icon: "xmark.circle.fill", label: "Missed", value: "\(manager.todayRecords.filter { $0.status == .missed }.count)", color: Theme.danger)
                miniStat(icon: "forward.fill", label: "Skipped", value: "\(manager.todayRecords.filter { $0.status == .skipped }.count)", color: Theme.warm)
            }
            Spacer()
        }
        .glowCard()
    }

    private func miniStat(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color).frame(width: 18)
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(color)
        }
    }

    private func nextDoseCard(_ record: IntakeRecord) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "bell.fill").font(.system(size: 12)).foregroundStyle(Theme.accent)
                Text("Next Up").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
                Spacer()
                Text(timeString(hour: record.scheduledHour)).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
            }
            HStack(spacing: 14) {
                Text(record.supplementEmoji).font(.system(size: 28))
                    .frame(width: 50, height: 50)
                    .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.supplementName).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                    if let sup = manager.supplements.first(where: { $0.id == record.supplementId }) {
                        Text(sup.dosageText).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { withAnimation(.spring(response: 0.3)) { manager.skipDose(record) } } label: {
                        Image(systemName: "forward.fill").font(.system(size: 14)).foregroundStyle(Theme.warm)
                            .frame(width: 40, height: 40).background(Theme.warm.opacity(0.12), in: Circle())
                    }
                    Button { withAnimation(.spring(response: 0.3)) { manager.takeDose(record) } } label: {
                        Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.bg)
                            .frame(width: 44, height: 44).background(Theme.success, in: Circle())
                    }
                }
            }
        }
        .glowCard(Theme.card.opacity(0.9))
    }

    private var lowStockBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundStyle(Theme.warm)
                Text("Low Stock").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.warm)
            }
            ForEach(manager.lowStockSups) { sup in
                HStack(spacing: 8) {
                    Text(sup.emoji).font(.system(size: 14))
                    Text(sup.name).font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.text)
                    Spacer()
                    Text("\(sup.pillsRemaining) left").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.warm)
                }
            }
        }
        .glowCard()
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            if manager.todayRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "pills").font(.system(size: 28)).foregroundStyle(Theme.muted)
                    Text("No supplements scheduled").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30).glowCard()
            } else {
                ForEach(manager.todayRecords) { record in DoseRow(record: record) }
            }
        }
    }
}

struct DoseRow: View {
    @EnvironmentObject var manager: ShelfManager
    let record: IntakeRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(timeString(hour: record.scheduledHour))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.sub).frame(width: 55, alignment: .leading)
            Text(record.supplementEmoji).font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(record.status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(record.supplementName).font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(record.status == .taken ? Theme.text.opacity(0.5) : Theme.text)
                    .strikethrough(record.status == .taken, color: Theme.success)
                if let sup = manager.supplements.first(where: { $0.id == record.supplementId }) {
                    Text(sup.dosageText).font(.system(size: 11, design: .rounded)).foregroundStyle(Theme.sub)
                }
            }
            Spacer()
            if record.status == .pending {
                HStack(spacing: 6) {
                    Button { withAnimation(.spring(response: 0.3)) { manager.skipDose(record) } } label: {
                        Image(systemName: "forward.fill").font(.system(size: 10)).foregroundStyle(Theme.warm)
                            .frame(width: 30, height: 30).background(Theme.warm.opacity(0.12), in: Circle())
                    }
                    Button { withAnimation(.spring(response: 0.3)) { manager.takeDose(record) } } label: {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.bg)
                            .frame(width: 30, height: 30).background(Theme.success, in: Circle())
                    }
                }
            } else {
                Button { withAnimation { manager.undoDose(record) } } label: {
                    Image(systemName: record.status.icon).font(.system(size: 18)).foregroundStyle(record.status.color)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
    }
}
