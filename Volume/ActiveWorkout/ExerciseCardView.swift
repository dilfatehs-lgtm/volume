import SwiftUI

/// One exercise inside a workout: the sets already logged, and the editor for the next
/// one.
///
/// Logging a set is a single tap once the numbers are right, and the numbers start out
/// right — pre-filled from the previous set, or from the last time this exercise was
/// performed in this workout.
struct ExerciseCardView: View {

    let entry: ExerciseEntry
    let model: ActiveWorkoutModel
    let unit: WeightUnit

    @State private var reps = 8
    @State private var weight: Double?
    @State private var showsWeightField = false
    @State private var didSeedDraft = false
    @State private var editingSet: SetEntry?
    @State private var padField: PadField?
    @State private var confirmingRemoval = false

    private enum PadField: String, Identifiable {
        case reps, weight
        var id: String { rawValue }
    }

    private var lastTime: ExerciseEntry? { model.lastTime(for: entry) }

    var body: some View {
        // Ties this card to every mutation the model makes. SwiftData's to-many
        // relationship changes don't reliably invalidate the view on their own, so
        // without this a freshly logged set doesn't appear until an unrelated redraw.
        let _ = model.changeCount

        return VStack(alignment: .leading, spacing: 14) {
            header

            if !entry.setsSorted.isEmpty {
                VStack(spacing: 8) {
                    ForEach(entry.setsSorted) { set in
                        loggedSetRow(set)
                    }
                }
            }

            Divider().overlay(Theme.hairline)

            editor
        }
        .padding(16)
        .cardBackground()
        .onAppear(perform: seedDraftIfNeeded)
        .sheet(item: $editingSet) { set in
            SetEditorSheet(set: set, unit: unit, model: model)
        }
        .sheet(item: $padField) { field in
            switch field {
            case .reps:
                NumberPadSheet(title: "Reps", initialValue: Double(reps)) { value in
                    reps = max(Int(value), 0)
                }
            case .weight:
                NumberPadSheet(title: "Weight",
                               suffix: unit.shortName,
                               allowsDecimal: true,
                               initialValue: weight ?? 0) { value in
                    weight = value > 0 ? value : nil
                }
            }
        }
        .confirmationDialog("Remove \(entry.displayName)?",
                            isPresented: $confirmingRemoval,
                            titleVisibility: .visible) {
            Button("Remove exercise", role: .destructive) {
                model.removeExercise(entry)
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This removes it from today's workout, including any sets you logged.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(Theme.label(19, weight: .heavy))
                    .foregroundStyle(.primary)

                if let lastTime, let lastSet = lastTime.setsSorted.last {
                    Text("Last time: \(setSummary(lastSet))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if entry.isBodyweight {
                    Text("Bodyweight")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                ScorePill(score: VolumeScore.score(for: entry, in: unit))
                Button {
                    confirmingRemoval = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: Theme.minTapTarget, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(entry.displayName)")
            }
        }
    }

    // MARK: - Logged sets

    private func loggedSetRow(_ set: SetEntry) -> some View {
        Button {
            editingSet = set
        } label: {
            HStack(spacing: 12) {
                Text("\(set.order + 1)")
                    .font(Theme.label(14, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Theme.surface))

                Text(setSummary(set))
                    .font(Theme.label(17, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text(VolumeScore.format(VolumeScore.score(for: set, in: unit)))
                    .font(Theme.label(16, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set \(set.order + 1), \(spokenSummary(set))")
        .accessibilityHint("Opens the set editor")
    }

    // MARK: - Next-set editor

    private var editor: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BigStepper(title: "Reps",
                           value: Double(reps),
                           step: 1,
                           range: 0...100,
                           format: { String(Int($0)) },
                           onChange: { reps = Int($0) },
                           onTapValue: { padField = .reps })

                if showsWeightField {
                    BigStepper(title: "Weight",
                               value: weight ?? 0,
                               step: unit.step,
                               range: 0...2000,
                               suffix: unit.shortName,
                               format: formatWeight,
                               onChange: { weight = $0 > 0 ? $0 : nil },
                               onTapValue: { padField = .weight })
                }
            }

            if !showsWeightField {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showsWeightField = true
                        if weight == nil { weight = unit.step * 2 }
                    }
                } label: {
                    Label("Add weight", systemImage: "plus.circle.fill")
                        .font(Theme.label(15, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .accessibilityHint("For weighted bodyweight exercises, like weighted pull-ups")
            }

            Button {
                model.addSet(to: entry, reps: reps, weight: showsWeightField ? weight : nil)
            } label: {
                Label("Log set", systemImage: "plus")
            }
            .buttonStyle(BigButtonStyle(kind: .primary, size: 18))
            .disabled(reps <= 0)
            .accessibilityLabel("Log set: \(reps) reps\(showsWeightField && weight != nil ? " at \(formatWeight(weight!)) \(unit.spokenName)" : "")")
        }
    }

    // MARK: - Helpers

    private func seedDraftIfNeeded() {
        guard !didSeedDraft else { return }
        didSeedDraft = true

        // Prefer the last set logged today, then the same exercise last time, then a
        // plain default. Whatever the source, the user should mostly just tap "Log set".
        if let lastSet = entry.setsSorted.last {
            reps = lastSet.reps
            weight = lastSet.weight(in: unit)
        } else if let previousSet = lastTime?.setsSorted.last {
            reps = previousSet.reps
            weight = previousSet.weight(in: unit)
        } else if !entry.isBodyweight {
            weight = unit == .pounds ? 45 : 20
        }

        showsWeightField = (weight ?? 0) > 0 || !entry.isBodyweight
    }

    private func formatWeight(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func setSummary(_ set: SetEntry) -> String {
        guard let value = set.weight(in: unit), value > 0 else {
            return "\(set.reps) reps"
        }
        return "\(set.reps) × \(formatWeight(value)) \(unit.shortName)"
    }

    private func spokenSummary(_ set: SetEntry) -> String {
        guard let value = set.weight(in: unit), value > 0 else {
            return "\(set.reps) reps, bodyweight"
        }
        return "\(set.reps) reps at \(formatWeight(value)) \(unit.spokenName)"
    }
}

// MARK: - Editing an already-logged set

struct SetEditorSheet: View {

    let set: SetEntry
    let unit: WeightUnit
    let model: ActiveWorkoutModel

    @Environment(\.dismiss) private var dismiss
    @State private var reps = 0
    @State private var weight: Double?
    @State private var padField: PadField?

    private enum PadField: String, Identifiable {
        case reps, weight
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(alignment: .top, spacing: 12) {
                    BigStepper(title: "Reps",
                               value: Double(reps),
                               step: 1,
                               range: 0...100,
                               format: { String(Int($0)) },
                               onChange: { reps = Int($0) },
                               onTapValue: { padField = .reps })

                    BigStepper(title: "Weight",
                               value: weight ?? 0,
                               step: unit.step,
                               range: 0...2000,
                               suffix: unit.shortName,
                               format: { $0 == $0.rounded() ? String(Int($0)) : String(format: "%.1f", $0) },
                               onChange: { weight = $0 > 0 ? $0 : nil },
                               onTapValue: { padField = .weight })
                }

                Text("Leave the weight at 0 for a bodyweight set.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Save changes") {
                    model.updateSet(set, reps: reps, weight: weight)
                    Haptics.tap()
                    dismiss()
                }
                .buttonStyle(.big)

                Button("Delete this set", role: .destructive) {
                    model.deleteSet(set)
                    Haptics.warning()
                    dismiss()
                }
                .buttonStyle(.bigDestructive)

                Spacer()
            }
            .padding(Theme.gutter)
            .navigationTitle("Set \(set.order + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(420)])
        .sheet(item: $padField) { field in
            switch field {
            case .reps:
                NumberPadSheet(title: "Reps", initialValue: Double(reps)) { reps = max(Int($0), 0) }
            case .weight:
                NumberPadSheet(title: "Weight",
                               suffix: unit.shortName,
                               allowsDecimal: true,
                               initialValue: weight ?? 0) { weight = $0 > 0 ? $0 : nil }
            }
        }
        .onAppear {
            reps = set.reps
            weight = set.weight(in: unit)
        }
    }
}
