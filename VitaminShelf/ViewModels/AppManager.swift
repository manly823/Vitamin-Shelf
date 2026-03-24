import SwiftUI

final class ShelfManager: ObservableObject {
    @Published var supplements: [Supplement] = [] {
        didSet { save("vs_sups", supplements); NotificationHelper.shared.scheduleAll(for: supplements) }
    }
    @Published var records: [IntakeRecord] = [] { didSet { save("vs_records", records) } }
    @Published var onboardingDone: Bool { didSet { UserDefaults.standard.set(onboardingDone, forKey: "vs_onboarding") } }

    private let todayKey: String

    init() {
        todayKey = Date().dateKey
        onboardingDone = UserDefaults.standard.bool(forKey: "vs_onboarding")
        supplements = Storage.shared.load(forKey: "vs_sups", default: Supplement.catalog)
        records = Storage.shared.load(forKey: "vs_records", default: [])
        cleanOldRecords()
        generateTodayRecords()
        markMissedPast()
    }

    private func save<T: Codable>(_ key: String, _ value: T) { Storage.shared.save(value, forKey: key) }

    // MARK: - Record Generation

    func generateTodayRecords() {
        let active = supplements.filter(\.isActive)
        for sup in active {
            for hour in sup.scheduledHours {
                let exists = records.contains { $0.supplementId == sup.id && $0.dateKey == todayKey && $0.scheduledHour == hour }
                if !exists {
                    records.append(IntakeRecord(supplementId: sup.id, supplementName: sup.name, supplementEmoji: sup.emoji, dateKey: todayKey, scheduledHour: hour))
                }
            }
        }
    }

    func markMissedPast() {
        let cal = Calendar.current
        let nowHour = cal.component(.hour, from: Date())
        for i in records.indices {
            if records[i].status == .pending {
                if records[i].dateKey < todayKey {
                    records[i].status = .missed
                } else if records[i].dateKey == todayKey && records[i].scheduledHour < nowHour - 2 {
                    records[i].status = .missed
                }
            }
        }
    }

    private func cleanOldRecords() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!.dateKey
        records.removeAll { $0.dateKey < cutoff }
    }

    // MARK: - Supplements CRUD

    func addSupplement(_ sup: Supplement) { supplements.append(sup) }
    func deleteSupplement(_ sup: Supplement) {
        supplements.removeAll { $0.id == sup.id }
        records.removeAll { $0.supplementId == sup.id }
    }
    func toggleActive(_ sup: Supplement) {
        guard let idx = supplements.firstIndex(where: { $0.id == sup.id }) else { return }
        supplements[idx].isActive.toggle()
        if supplements[idx].isActive { generateTodayRecords() }
    }
    func toggleNotify(_ sup: Supplement) {
        guard let idx = supplements.firstIndex(where: { $0.id == sup.id }) else { return }
        supplements[idx].notifyEnabled.toggle()
    }
    func refill(_ sup: Supplement) {
        guard let idx = supplements.firstIndex(where: { $0.id == sup.id }) else { return }
        supplements[idx].pillsRemaining = supplements[idx].pillsPerPack
    }
    func updatePillCount(_ sup: Supplement, count: Int) {
        guard let idx = supplements.firstIndex(where: { $0.id == sup.id }) else { return }
        supplements[idx].pillsRemaining = max(0, count)
    }

    // MARK: - Intake Actions

    func takeDose(_ record: IntakeRecord) {
        guard let ri = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[ri].status = .taken
        records[ri].takenAt = Date()
        if let si = supplements.firstIndex(where: { $0.id == record.supplementId }) {
            supplements[si].pillsRemaining = max(0, supplements[si].pillsRemaining - 1)
            if supplements[si].isLowStock {
                NotificationHelper.shared.sendLowStockAlert(for: supplements[si])
            }
        }
    }

    func skipDose(_ record: IntakeRecord) {
        guard let ri = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[ri].status = .skipped
    }

    func undoDose(_ record: IntakeRecord) {
        guard let ri = records.firstIndex(where: { $0.id == record.id }) else { return }
        let was = records[ri].status
        records[ri].status = .pending
        records[ri].takenAt = nil
        if was == .taken, let si = supplements.firstIndex(where: { $0.id == record.supplementId }) {
            supplements[si].pillsRemaining += 1
        }
    }

    // MARK: - Queries

    var todayRecords: [IntakeRecord] {
        records.filter { $0.dateKey == todayKey }.sorted { $0.scheduledHour < $1.scheduledHour }
    }
    var todayTaken: Int { todayRecords.filter { $0.status == .taken }.count }
    var todayTotal: Int { todayRecords.count }
    var todayProgress: Double { todayTotal == 0 ? 0 : Double(todayTaken) / Double(todayTotal) }
    var nextPending: IntakeRecord? { todayRecords.first { $0.status == .pending } }

    var activeSups: [Supplement] { supplements.filter(\.isActive).sorted { $0.name < $1.name } }
    var inactiveSups: [Supplement] { supplements.filter { !$0.isActive }.sorted { $0.name < $1.name } }
    var lowStockSups: [Supplement] { supplements.filter { $0.isActive && $0.isLowStock } }
    var emptySups: [Supplement] { supplements.filter { $0.isActive && $0.isEmpty } }

    func records(for dateKey: String) -> [IntakeRecord] {
        records.filter { $0.dateKey == dateKey }.sorted { $0.scheduledHour < $1.scheduledHour }
    }

    // MARK: - Stats

    func adherenceRate(days: Int) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!.dateKey
        let relevant = records.filter { $0.dateKey >= cutoff && $0.dateKey <= todayKey && $0.status != .pending }
        guard !relevant.isEmpty else { return 0 }
        let taken = relevant.filter { $0.status == .taken }.count
        return Double(taken) / Double(relevant.count)
    }

    func currentStreak() -> Int {
        var streak = 0
        var date = Date()
        let cal = Calendar.current
        for _ in 0..<90 {
            let key = date.dateKey
            let dayRecords = records.filter { $0.dateKey == key }
            if dayRecords.isEmpty { break }
            let allTaken = dayRecords.allSatisfy { $0.status == .taken }
            if allTaken { streak += 1 } else { break }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    func totalTaken() -> Int { records.filter { $0.status == .taken }.count }
    func totalMissed() -> Int { records.filter { $0.status == .missed }.count }
    func totalSkipped() -> Int { records.filter { $0.status == .skipped }.count }

    func weeklyAdherence() -> [ChartPoint] {
        let cal = Calendar.current
        var points: [ChartPoint] = []
        for i in (0..<7).reversed() {
            let date = cal.date(byAdding: .day, value: -i, to: Date())!
            let key = date.dateKey
            let day = records.filter { $0.dateKey == key && $0.status != .pending }
            let taken = day.filter { $0.status == .taken }.count
            let rate = day.isEmpty ? 0 : Double(taken) / Double(day.count) * 100
            let f = DateFormatter()
            f.dateFormat = "EEE"
            points.append(ChartPoint(id: key, label: f.string(from: date), value: rate))
        }
        return points
    }

    func categoryBreakdown() -> [ChartPoint] {
        SupCategory.allCases.compactMap { cat in
            let count = activeSups.filter { $0.category == cat }.count
            guard count > 0 else { return nil }
            return ChartPoint(id: cat.rawValue, label: cat.name, value: Double(count))
        }
    }

    func mostMissedSups() -> [(name: String, emoji: String, count: Int)] {
        let missed = records.filter { $0.status == .missed }
        let grouped = Dictionary(grouping: missed, by: \.supplementId)
        return grouped.map { (key, val) in
            (name: val.first?.supplementName ?? "?", emoji: val.first?.supplementEmoji ?? "💊", count: val.count)
        }
        .sorted { $0.count > $1.count }
        .prefix(5)
        .map { $0 }
    }

    func dayAdherence(dateKey: String) -> Double {
        let day = records.filter { $0.dateKey == dateKey && $0.status != .pending }
        guard !day.isEmpty else { return -1 }
        let taken = day.filter { $0.status == .taken }.count
        return Double(taken) / Double(day.count)
    }

    // MARK: - Reset

    func resetAllData() {
        supplements = Supplement.catalog
        records = []
        onboardingDone = false
        UserDefaults.standard.removeObject(forKey: "vs_onboarding")
        NotificationHelper.shared.cancelAll()
    }
}
