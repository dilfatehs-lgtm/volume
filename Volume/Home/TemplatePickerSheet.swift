import SwiftData
import SwiftUI

/// Choose which workout you're doing. Each card carries that workout's own last score —
/// the target you're about to chase, visible before you commit to it.
struct TemplatePickerSheet: View {

    let templates: [WorkoutTemplate]
    let sessions: [WorkoutSession]
    let unit: WeightUnit
    /// Pre-set when arriving from a specific day in the Calendar.
    var initialDate: Date = Date()
    let onStart: (WorkoutTemplate, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var creatingNew = false
    @State private var startDate = Date()
    @State private var editingDate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Defaults to now, so the common path is still two taps and no date UI
                    // gets in the way of logging a workout you just did.
                    WorkoutDateRow(date: startDate) { editingDate = true }

                    if templates.isEmpty {
                        EmptyStateView(icon: "square.stack.3d.up.fill",
                                       title: "Name your first workout",
                                       message: "Call it whatever you call it — Push, Leg Day, Tuesday. You'll compare against it next time.")
                    }

                    ForEach(templates) { template in
                        templateCard(template)
                    }

                    Button {
                        creatingNew = true
                    } label: {
                        Label("New workout", systemImage: "plus")
                    }
                    .buttonStyle(templates.isEmpty ? BigButtonStyle(kind: .primary)
                                                   : BigButtonStyle(kind: .secondary))
                    .padding(.top, 4)
                }
                .padding(Theme.gutter)
            }
            .background(Theme.surface)
            .navigationTitle("Which workout?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $creatingNew) {
                NewTemplateSheet(existing: templates) { template in
                    dismiss()
                    onStart(template, startDate)
                }
            }
            .sheet(isPresented: $editingDate) {
                WorkoutDateSheet(date: $startDate)
            }
            .onAppear { startDate = initialDate }
        }
    }

    private func templateCard(_ template: WorkoutTemplate) -> some View {
        Button {
            dismiss()
            onStart(template, startDate)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(Theme.label(22, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let last = SessionHistory.lastCompletedSession(for: template, among: sessions) {
                        Text("Last: \(VolumeScore.format(VolumeScore.score(for: last, in: unit)))  ·  \(last.date.formatted(.dateTime.month().day()))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not done yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Theme.accent)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .cardBackground(raised: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: template))
        .accessibilityHint("Starts this workout")
    }

    private func accessibilityLabel(for template: WorkoutTemplate) -> String {
        guard let last = SessionHistory.lastCompletedSession(for: template, among: sessions) else {
            return "\(template.name), not done yet"
        }
        return "\(template.name), last score \(VolumeScore.format(VolumeScore.score(for: last, in: unit)))"
    }
}

// MARK: - Creating a template

struct NewTemplateSheet: View {

    let existing: [WorkoutTemplate]
    let onCreate: (WorkoutTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var similarTemplate: WorkoutTemplate? {
        TemplateNameMatcher.firstMatch(for: trimmed, in: existing)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("What do you call this workout?")
                    .font(Theme.label(20, weight: .heavy))

                TextField("Push, Leg Day, Tuesday…", text: $name)
                    .font(Theme.label(22, weight: .bold))
                    .textInputAutocapitalization(.words)
                    .focused($focused)
                    .padding(16)
                    .cardBackground()
                    .accessibilityLabel("Workout name")

                if let similarTemplate {
                    duplicateNudge(similarTemplate)
                } else {
                    Button("Create and start") {
                        create()
                    }
                    .buttonStyle(.big)
                    .disabled(trimmed.isEmpty)
                }

                Spacer()
            }
            .padding(Theme.gutter)
            .background(Theme.surface)
            .navigationTitle("New workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.height(430)])
    }

    /// Using the existing template is the *primary* action here, because splitting one
    /// workout across two names quietly wipes out its score history.
    private func duplicateNudge(_ template: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("You already have “\(template.name)”", systemImage: "exclamationmark.circle.fill")
                .font(Theme.label(15, weight: .bold))
                .foregroundStyle(Theme.accent)

            Text("Logging this one under a new name starts its score history over.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Use “\(template.name)”") {
                dismiss()
                onCreate(template)
            }
            .buttonStyle(.big)

            Button("Create “\(trimmed)” anyway") {
                create()
            }
            .buttonStyle(.bigSecondary)
        }
        .padding(16)
        .cardBackground()
    }

    private func create() {
        let template = WorkoutTemplate(name: trimmed)
        context.insert(template)
        try? context.save()
        Haptics.tap()
        dismiss()
        onCreate(template)
    }
}
