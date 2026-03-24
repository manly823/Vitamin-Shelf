import SwiftUI

struct LogView: View {
    @EnvironmentObject var manager: ShelfManager
    @State private var selectedDay: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                calendarGrid
                if let day = selectedDay { dayDetail(day) }
                recentSection
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Intake Log").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text("Last 28 days").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var last28Days: [Date] {
        let cal = Calendar.current
        return (0..<28).reversed().map { cal.date(byAdding: .day, value: -$0, to: Date())! }
    }

    private func dayColor(_ date: Date) -> Color {
        let key = date.dateKey
        let adh = manager.dayAdherence(dateKey: key)
        if adh < 0 { return Theme.muted.opacity(0.3) }
        if adh >= 0.9 { return Theme.success }
        if adh >= 0.5 { return Theme.warm }
        if adh > 0 { return Theme.danger.opacity(0.7) }
        return Theme.danger
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            let days = last28Days
            let firstWeekday = Calendar.current.component(.weekday, from: days.first!) 
            let mondayOffset = (firstWeekday + 5) % 7

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<mondayOffset, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6).fill(Color.clear).frame(height: 36)
                }
                ForEach(days, id: \.dateKey) { date in
                    let key = date.dateKey
                    let isSelected = selectedDay == key
                    let isToday = key == Date().dateKey
                    Button { withAnimation { selectedDay = selectedDay == key ? nil : key } } label: {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? Theme.bg : Theme.text)
                        }
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? dayColor(date) : dayColor(date).opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isToday ? Theme.accent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            HStack(spacing: 12) {
                legendDot(Theme.success, "100%")
                legendDot(Theme.warm, "50%+")
                legendDot(Theme.danger, "<50%")
                legendDot(Theme.muted.opacity(0.3), "No data")
            }
            .padding(.top, 4)
        }
        .glowCard()
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 9, design: .rounded)).foregroundStyle(Theme.sub)
        }
    }

    private func dayDetail(_ dateKey: String) -> some View {
        let recs = manager.records(for: dateKey)
        return VStack(alignment: .leading, spacing: 10) {
            Text(dateKey).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.accent)
            if recs.isEmpty {
                Text("No records for this day").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            } else {
                ForEach(recs) { rec in
                    HStack(spacing: 10) {
                        Image(systemName: rec.status.icon).font(.system(size: 14)).foregroundStyle(rec.status.color).frame(width: 20)
                        Text(rec.supplementEmoji).font(.system(size: 14))
                        Text(rec.supplementName).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
                        Spacer()
                        Text(timeString(hour: rec.scheduledHour)).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.sub)
                    }
                }
            }
        }
        .glowCard()
    }

    private var recentSection: some View {
        let recentTaken = manager.records.filter { $0.status == .taken }.suffix(10).reversed()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
            if recentTaken.isEmpty {
                Text("No activity yet").font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                ForEach(Array(recentTaken)) { rec in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(Theme.success)
                        Text(rec.supplementEmoji).font(.system(size: 13))
                        Text(rec.supplementName).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(rec.dateKey.suffix(5)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                            if let t = rec.takenAt {
                                Text(t.shortTime).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.sub)
                            }
                        }
                    }
                }
            }
        }
        .glowCard()
    }
}
