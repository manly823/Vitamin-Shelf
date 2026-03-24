import SwiftUI

struct ShelfView: View {
    @EnvironmentObject var manager: ShelfManager
    @State private var showAdd = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                if !manager.activeSups.isEmpty { activeSection }
                if !manager.inactiveSups.isEmpty { inactiveSection }
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .background(Theme.bg)
        .sheet(isPresented: $showAdd) { AddSupplementSheet() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Shelf").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                Text("\(manager.activeSups.count) active · \(manager.supplements.count) total")
                    .font(.system(size: 13, design: .rounded)).foregroundStyle(Theme.sub)
            }
            Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.bg).frame(width: 40, height: 40)
                    .background(Theme.accent, in: Circle())
            }
        }
        .padding(.top, 8)
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.success)
            ForEach(manager.activeSups) { sup in SupplementCard(supplement: sup) }
        }
    }

    private var inactiveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Inactive").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.muted)
            ForEach(manager.inactiveSups) { sup in SupplementCard(supplement: sup) }
        }
    }
}

struct SupplementCard: View {
    @EnvironmentObject var manager: ShelfManager
    let supplement: Supplement
    @State private var expanded = false

    private var stockColor: Color {
        if supplement.isEmpty { return Theme.danger }
        if supplement.isLowStock { return Theme.warm }
        return Theme.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: { mainRow }
            if expanded { detailSection.transition(.opacity.combined(with: .move(edge: .top))) }
        }
        .glowCard()
        .opacity(supplement.isActive ? 1 : 0.6)
    }

    private var mainRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(supplement.emoji).font(.system(size: 24))
                    .frame(width: 48, height: 48)
                    .background(supplement.category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(supplement.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                    HStack(spacing: 6) {
                        Text(supplement.dosageText).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                        Text("·").foregroundStyle(Theme.muted)
                        Text(supplement.frequency.name).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(supplement.pillsRemaining)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(stockColor)
                    Text("left").font(.system(size: 10, design: .rounded)).foregroundStyle(Theme.sub)
                }
            }
            PillBar(progress: supplement.pillProgress, color: stockColor)
        }
    }

    private var detailSection: some View {
        VStack(spacing: 8) {
            detailRow("Category", supplement.category.name)
            detailRow("Schedule", supplement.scheduledHours.map { timeString(hour: $0) }.joined(separator: ", "))
            detailRow("Pack Size", "\(supplement.pillsPerPack)")
            detailRow("Notifications", supplement.notifyEnabled ? "On" : "Off")
            if !supplement.notes.isEmpty { detailRow("Notes", supplement.notes) }
            Divider().background(Theme.muted)
            HStack(spacing: 12) {
                Button { withAnimation { manager.toggleActive(supplement) } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: supplement.isActive ? "pause.fill" : "play.fill").font(.system(size: 11))
                        Text(supplement.isActive ? "Deactivate" : "Activate").font(.system(size: 12, weight: .semibold, design: .rounded))
                    }.foregroundStyle(supplement.isActive ? Theme.warm : Theme.success)
                }
                Button { withAnimation { manager.toggleNotify(supplement) } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: supplement.notifyEnabled ? "bell.slash.fill" : "bell.fill").font(.system(size: 11))
                        Text(supplement.notifyEnabled ? "Mute" : "Unmute").font(.system(size: 12, weight: .semibold, design: .rounded))
                    }.foregroundStyle(Theme.info)
                }
                Button { withAnimation { manager.refill(supplement) } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                        Text("Refill").font(.system(size: 12, weight: .semibold, design: .rounded))
                    }.foregroundStyle(Theme.accent)
                }
                Spacer()
                Button { withAnimation { manager.deleteSupplement(supplement) } } label: {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(Theme.danger)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.sub)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.text)
        }
    }
}

// MARK: - Add Supplement

struct AddSupplementSheet: View {
    @EnvironmentObject var manager: ShelfManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var emoji = "💊"
    @State private var dosage = ""
    @State private var unit: DoseUnit = .mg
    @State private var category: SupCategory = .vitamin
    @State private var frequency: DoseFrequency = .once
    @State private var pillsPerPack = "60"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                        TextField("e.g. Vitamin D3", text: $name)
                            .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                            .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }.glowCard()

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dosage").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                            TextField("500", text: $dosage).keyboardType(.decimalPad)
                                .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                                .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                            Menu {
                                ForEach(DoseUnit.allCases) { u in Button(u.symbol) { unit = u } }
                            } label: {
                                HStack {
                                    Text(unit.symbol).font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 12)).foregroundStyle(Theme.muted)
                                }
                                .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }.glowCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SupCategory.allCases) { cat in
                                Button { category = cat } label: {
                                    VStack(spacing: 3) {
                                        Text(cat.emoji).font(.system(size: 16))
                                        Text(cat.name).font(.system(size: 9, weight: .semibold, design: .rounded))
                                            .foregroundStyle(category == cat ? Theme.bg : Theme.text).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(category == cat ? cat.color : Theme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }.glowCard()

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                            Menu {
                                ForEach(DoseFrequency.allCases) { f in Button(f.name) { frequency = f } }
                            } label: {
                                HStack {
                                    Text(frequency.name).font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.text)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 12)).foregroundStyle(Theme.muted)
                                }
                                .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pack Size").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.sub)
                            TextField("60", text: $pillsPerPack).keyboardType(.numberPad)
                                .font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.text)
                                .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }.glowCard()

                    Button {
                        let d = Double(dosage) ?? 0
                        let p = Int(pillsPerPack) ?? 60
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, d > 0 else { return }
                        var sup = Supplement(name: name, emoji: emoji, dosage: d, unit: unit, category: category, frequency: frequency, pillsRemaining: p, pillsPerPack: p)
                        sup.scheduledHours = frequency.defaultHours
                        manager.addSupplement(sup)
                        manager.generateTodayRecords()
                        dismiss()
                    } label: {
                        Text("Add Supplement").font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.bg).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.muted : Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.sub)
                }
            }
        }
    }
}
