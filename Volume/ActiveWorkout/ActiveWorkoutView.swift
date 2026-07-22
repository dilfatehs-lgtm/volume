import SwiftData
import SwiftUI

/// The product. Everything else in the app exists to get here or to look back at it.
struct ActiveWorkoutView: View {

    @State private var model: ActiveWorkoutModel
    @State private var showingPicker = false
    @State private var summary: WorkoutSummary?
    @State private var confirmingFinish = false
    @State private var confirmingDiscard = false
    @State private var editingDate = false
    @State private var draftDate = Date()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let unit: WeightUnit
    private let mode: ActiveWorkoutMode

    init(session: WorkoutSession,
         context: ModelContext,
         unit: WeightUnit,
         mode: ActiveWorkoutMode = .live) {
        self.unit = unit
        self.mode = mode
        _model = State(initialValue: ActiveWorkoutModel(session: session,
                                                        context: context,
                                                        unit: unit,
                                                        mode: mode))
    }

    var body: some View {
        Group {
            if let summary {
                WorkoutSummaryView(summary: summary) { dismiss() }
            } else {
                workout
            }
        }
        .background(Theme.surface)
    }

    // MARK: - Workout

    private var workout: some View {
        // See `ActiveWorkoutModel.changeCount` — keeps the score, ring and exercise list
        // in step with every logged set.
        let _ = model.changeCount

        return NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                        .padding(.top, 8)

                    // Shown when the workout isn't today's, so it's obvious you're logging
                    // into the past rather than silently misfiling a session.
                    if mode == .editingPast || WorkoutDateLabel.isBackdated(model.session.date) {
                        WorkoutDateRow(date: model.session.date) {
                            editingDate = true
                        }
                    }

                    if model.canRepeatLastTime {
                        repeatLastTimeButton
                    }

                    ForEach(model.session.entriesSorted) { entry in
                        ExerciseCardView(entry: entry, model: model, unit: unit)
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                    .buttonStyle(.bigSecondary)

                    // Closing keeps a workout in progress; this is the way to be rid of one.
                    Button(role: .destructive) {
                        confirmingDiscard = true
                    } label: {
                        Label(mode == .editingPast ? "Delete this workout" : "Discard workout",
                              systemImage: "trash")
                    }
                    .buttonStyle(.bigDestructive)
                    .padding(.top, 4)

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 12)
            }
            .background(Theme.surface)
            .navigationTitle(model.session.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        model.discardIfEmpty()
                        dismiss()
                    } label: {
                        Text(mode == .editingPast ? "Cancel" : "Close")
                    }
                    .accessibilityHint(mode == .editingPast
                                       ? "Closes the editor"
                                       : "Leaves this workout in progress. You can pick it back up from Home.")
                }
            }
            .safeAreaInset(edge: .bottom) {
                finishBar
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { exercise in
                    model.addExercise(exercise)
                }
            }
            .sheet(isPresented: $editingDate) {
                WorkoutDateSheet(date: $draftDate)
                    .onDisappear { model.updateDate(draftDate) }
            }
            .onChange(of: editingDate) { _, isEditing in
                if isEditing { draftDate = model.session.date }
            }
            .confirmationDialog("Finish this workout?",
                                isPresented: $confirmingFinish,
                                titleVisibility: .visible) {
                Button("Finish workout") { summary = model.finish() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("Your score will be saved as \(VolumeScore.format(model.liveScore)).")
            }
            .confirmationDialog(mode == .editingPast ? "Delete this workout?"
                                                     : "Discard this workout?",
                                isPresented: $confirmingDiscard,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    model.discard()
                    dismiss()
                }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text(model.isEmpty
                     ? "Nothing has been logged yet, so nothing will be lost."
                     : "This permanently deletes the workout and all \(model.session.totalSets) of its sets. This can't be undone.")
            }
        }
        .overlay {
            if model.showCelebration {
                RecordCelebrationView(score: model.liveScore,
                                      previousScore: model.scoreToBeat ?? 0,
                                      streak: model.projectedStreak) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        model.showCelebration = false
                    }
                }
                .transition(.opacity)
                .task {
                    // Land, feel good, get out of the way so the user can keep lifting.
                    try? await Task.sleep(for: .seconds(3.2))
                    withAnimation(.easeOut(duration: 0.3)) {
                        model.showCelebration = false
                    }
                }
            }
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var hero: some View {
        VStack(spacing: 12) {
            if let target = model.scoreToBeat {
                ZStack {
                    ProgressRing(progress: model.progress, isRecord: model.hasBeatenTarget)
                        .frame(width: 248, height: 248)

                    VStack(spacing: 4) {
                        ScoreDisplay(score: model.liveScore,
                                     size: 60,
                                     isRecord: model.hasBeatenTarget)
                        Text(model.hasBeatenTarget ? "BEAT \(VolumeScore.format(target))"
                                                   : "OF \(VolumeScore.format(target))")
                            .font(Theme.label(13, weight: .heavy))
                            .tracking(1.2)
                            .foregroundStyle(model.hasBeatenTarget ? Theme.accent : .secondary)
                    }
                    .padding(.horizontal, 40)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Volume score")
                .accessibilityValue(scoreAccessibilityValue(target: target))

                if model.hasBeatenTarget {
                    Label("\(VolumeScore.formatDelta(model.delta ?? 0)) past last time",
                          systemImage: "flame.fill")
                        .font(Theme.label(16, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                        .accessibilityLabel("\(VolumeScore.formatDelta(model.delta ?? 0)) past last time")
                } else {
                    Text("Score to beat: \(VolumeScore.format(target))")
                        .font(Theme.label(15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            } else {
                ScoreDisplay(score: model.liveScore, size: 88, caption: "Volume score")
                    .padding(.vertical, 18)
                Text("First time doing \(model.session.displayName). Today sets the score to beat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        // Keeps the longer captions ("First time doing Back…") off the card edges.
        .padding(.horizontal, 22)
        .cardBackground()
    }

    private func scoreAccessibilityValue(target: Double) -> String {
        let score = VolumeScore.format(model.liveScore)
        if model.hasBeatenTarget {
            return "\(score). New record, \(VolumeScore.formatDelta(model.delta ?? 0)) past your last score of \(VolumeScore.format(target))."
        }
        return "\(score) of \(VolumeScore.format(target)) needed to beat last time."
    }

    // MARK: - Bars

    private var repeatLastTimeButton: some View {
        Button {
            model.repeatLastTime()
        } label: {
            Label("Repeat last time", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.bigSecondary)
        .accessibilityHint("Fills in the same exercises and sets as last time, so you only edit the numbers")
    }

    private var finishBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.hairline)
            Button {
                if mode == .editingPast {
                    // Every edit already saved as it was made; this just closes.
                    Haptics.tap()
                    dismiss()
                } else if model.isEmpty {
                    Haptics.warning()
                } else {
                    confirmingFinish = true
                }
            } label: {
                Label(mode == .editingPast ? "Done" : "Finish workout", systemImage: "checkmark")
            }
            .buttonStyle(.big)
            .disabled(mode == .live && model.isEmpty)
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .background(.bar)
    }
}
