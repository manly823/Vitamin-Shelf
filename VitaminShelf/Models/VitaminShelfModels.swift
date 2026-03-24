import SwiftUI

// MARK: - Enums

enum DoseUnit: String, Codable, CaseIterable, Identifiable {
    case mg, mcg, iu, ml, g, capsule, tablet, drop
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .mg: return "mg"
        case .mcg: return "mcg"
        case .iu: return "IU"
        case .ml: return "ml"
        case .g: return "g"
        case .capsule: return "cap"
        case .tablet: return "tab"
        case .drop: return "drops"
        }
    }
}

enum DoseFrequency: String, Codable, CaseIterable, Identifiable {
    case once, twice, thrice, weekly
    var id: String { rawValue }
    var name: String {
        switch self {
        case .once: return "Once daily"
        case .twice: return "Twice daily"
        case .thrice: return "3× daily"
        case .weekly: return "Weekly"
        }
    }
    var timesPerDay: Int {
        switch self {
        case .once: return 1
        case .twice: return 2
        case .thrice: return 3
        case .weekly: return 1
        }
    }
    var defaultHours: [Int] {
        switch self {
        case .once: return [9]
        case .twice: return [9, 21]
        case .thrice: return [8, 14, 21]
        case .weekly: return [9]
        }
    }
}

enum SupCategory: String, Codable, CaseIterable, Identifiable {
    case vitamin, mineral, amino, herb, probiotic, omega, other
    var id: String { rawValue }
    var name: String {
        switch self {
        case .vitamin: return "Vitamins"
        case .mineral: return "Minerals"
        case .amino: return "Amino Acids"
        case .herb: return "Herbs"
        case .probiotic: return "Probiotics"
        case .omega: return "Omega / Fats"
        case .other: return "Other"
        }
    }
    var emoji: String {
        switch self {
        case .vitamin: return "💊"
        case .mineral: return "⚡"
        case .amino: return "🧬"
        case .herb: return "🌿"
        case .probiotic: return "🦠"
        case .omega: return "🐟"
        case .other: return "✨"
        }
    }
    var color: Color {
        switch self {
        case .vitamin: return Theme.accent
        case .mineral: return Theme.info
        case .amino: return Theme.secondary
        case .herb: return Theme.success
        case .probiotic: return Theme.warm
        case .omega: return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .other: return Theme.sub
        }
    }
}

enum IntakeStatus: String, Codable {
    case pending, taken, skipped, missed
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .missed: return "xmark.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .pending: return Theme.sub
        case .taken: return Theme.success
        case .skipped: return Theme.warm
        case .missed: return Theme.danger
        }
    }
}

// MARK: - Supplement

struct Supplement: Codable, Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var dosage: Double
    var unit: DoseUnit
    var category: SupCategory
    var frequency: DoseFrequency
    var scheduledHours: [Int]
    var pillsRemaining: Int
    var pillsPerPack: Int
    var isActive: Bool
    var notifyEnabled: Bool
    var notes: String

    init(name: String, emoji: String, dosage: Double, unit: DoseUnit, category: SupCategory,
         frequency: DoseFrequency = .once, pillsRemaining: Int = 60, pillsPerPack: Int = 60,
         isActive: Bool = true, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.dosage = dosage
        self.unit = unit
        self.category = category
        self.frequency = frequency
        self.scheduledHours = frequency.defaultHours
        self.pillsRemaining = pillsRemaining
        self.pillsPerPack = pillsPerPack
        self.isActive = isActive
        self.notifyEnabled = true
        self.notes = notes
    }

    var pillProgress: Double { Double(pillsRemaining) / Double(max(pillsPerPack, 1)) }
    var isLowStock: Bool { pillsRemaining <= 7 && pillsRemaining > 0 }
    var isEmpty: Bool { pillsRemaining <= 0 }
    var dosageText: String { "\(dosage.clean) \(unit.symbol)" }

    static let catalog: [Supplement] = [
        Supplement(name: "Vitamin D3", emoji: "☀️", dosage: 2000, unit: .iu, category: .vitamin),
        Supplement(name: "Vitamin C", emoji: "🍊", dosage: 1000, unit: .mg, category: .vitamin),
        Supplement(name: "Omega-3", emoji: "🐟", dosage: 1000, unit: .mg, category: .omega),
        Supplement(name: "Magnesium", emoji: "🧲", dosage: 400, unit: .mg, category: .mineral),
        Supplement(name: "Zinc", emoji: "🛡️", dosage: 25, unit: .mg, category: .mineral),
        Supplement(name: "Vitamin B12", emoji: "🔴", dosage: 1000, unit: .mcg, category: .vitamin),
        Supplement(name: "Iron", emoji: "🩸", dosage: 18, unit: .mg, category: .mineral),
        Supplement(name: "Calcium", emoji: "🦴", dosage: 500, unit: .mg, category: .mineral, frequency: .twice),
        Supplement(name: "Probiotics", emoji: "🦠", dosage: 1, unit: .capsule, category: .probiotic),
        Supplement(name: "Collagen", emoji: "✨", dosage: 5, unit: .g, category: .amino),
        Supplement(name: "Ashwagandha", emoji: "🌿", dosage: 600, unit: .mg, category: .herb, isActive: false),
        Supplement(name: "CoQ10", emoji: "❤️", dosage: 100, unit: .mg, category: .other),
        Supplement(name: "Biotin", emoji: "💅", dosage: 5000, unit: .mcg, category: .vitamin),
        Supplement(name: "Turmeric", emoji: "🟡", dosage: 500, unit: .mg, category: .herb, isActive: false),
        Supplement(name: "Folic Acid", emoji: "🧬", dosage: 400, unit: .mcg, category: .vitamin),
        Supplement(name: "L-Theanine", emoji: "🍵", dosage: 200, unit: .mg, category: .amino, isActive: false),
        Supplement(name: "Vitamin K2", emoji: "🥬", dosage: 100, unit: .mcg, category: .vitamin),
        Supplement(name: "Melatonin", emoji: "🌙", dosage: 3, unit: .mg, category: .other, isActive: false),
        Supplement(name: "Creatine", emoji: "💪", dosage: 5, unit: .g, category: .amino, isActive: false),
        Supplement(name: "Spirulina", emoji: "🌊", dosage: 500, unit: .mg, category: .herb, isActive: false),
    ]
}

// MARK: - Intake Record

struct IntakeRecord: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let supplementName: String
    let supplementEmoji: String
    let dateKey: String
    let scheduledHour: Int
    var status: IntakeStatus
    var takenAt: Date?

    init(supplementId: UUID, supplementName: String, supplementEmoji: String, dateKey: String, scheduledHour: Int) {
        self.id = UUID()
        self.supplementId = supplementId
        self.supplementName = supplementName
        self.supplementEmoji = supplementEmoji
        self.dateKey = dateKey
        self.scheduledHour = scheduledHour
        self.status = .pending
        self.takenAt = nil
    }
}

// MARK: - Chart

struct ChartPoint: Identifiable {
    let id: String
    let label: String
    let value: Double
}

// MARK: - Helpers

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}

extension Date {
    var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
    var shortTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }
}

func timeString(hour: Int) -> String {
    let h = hour % 12 == 0 ? 12 : hour % 12
    let p = hour < 12 ? "AM" : "PM"
    return "\(h):00 \(p)"
}
