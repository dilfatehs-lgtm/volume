import SwiftData
import SwiftUI

/// Pick an exercise from the library, or make a new one.
///
/// Sections are a findability aid for a 53-item list, not a classification of the user's
/// training — the app never asks what body part a *workout* is.
struct ExercisePickerView: View {

    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var search = ""
    @State private var creatingCustom = false

    private var filtered: [Exercise] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var grouped: [(category: String, items: [Exercise])] {
        let byCategory = Dictionary(grouping: filtered) { $0.category.isEmpty ? "Custom" : $0.category }
        return byCategory
            .map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { lhs, rhs in
                let order = ExerciseLibrary.categoryOrder
                let l = order.firstIndex(of: lhs.category) ?? order.count
                let r = order.firstIndex(of: rhs.category) ?? order.count
                return l == r ? lhs.category < rhs.category : l < r
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        creatingCustom = true
                    } label: {
                        Label {
                            Text(search.isEmpty ? "Add your own exercise" : "Add “\(search)”")
                                .font(Theme.label(17, weight: .bold))
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        .frame(minHeight: Theme.minTapTarget)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(grouped, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.items) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(exercise.name)
                                        .font(Theme.label(17, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if exercise.isBodyweight {
                                        Text("BODYWEIGHT")
                                            .font(Theme.label(10, weight: .heavy))
                                            .tracking(0.6)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Theme.surface))
                                    }
                                }
                                .frame(minHeight: Theme.minTapTarget)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(exercise.isBodyweight
                                                ? "\(exercise.name), bodyweight"
                                                : exercise.name)
                            .accessibilityHint("Adds this exercise to your workout")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search exercises")
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $creatingCustom) {
                CustomExerciseSheet(initialName: search) { name, isBodyweight in
                    let exercise = Exercise(name: name,
                                            category: "Custom",
                                            isBodyweight: isBodyweight,
                                            isCustom: true)
                    context.insert(exercise)
                    try? context.save()
                    onSelect(exercise)
                    dismiss()
                }
            }
        }
    }
}

struct CustomExerciseSheet: View {

    let initialName: String
    let onCreate: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isBodyweight = false
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Sled Push", text: $name)
                        .font(Theme.label(18, weight: .semibold))
                        .focused($nameFocused)
                        .frame(minHeight: 44)
                }

                Section {
                    Toggle(isOn: $isBodyweight) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bodyweight exercise")
                                .font(Theme.label(16, weight: .semibold))
                            Text("Hides the weight box. You can still add weight later.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: Theme.minTapTarget)
                }
            }
            .navigationTitle("New exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onCreate(trimmedName, isBodyweight)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                name = initialName
                nameFocused = true
            }
        }
        .presentationDetents([.height(340)])
    }
}
