import SwiftData
import SwiftUI

/// Month view with a dot on every day you trained, and the full log for whichever day is
/// selected shown directly underneath — no modal, nothing hidden behind a gesture.
struct CalendarTabView: View {

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt) private var templates: [WorkoutTemplate]

    @State private var visibleMonth = Date()
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var presented: WorkoutPresentation?
    @State private var addingWorkout = false
    @State private var pendingDeletion: WorkoutSession?

    /// One piece of state for both cases, so a new backdated workout and an edit of an
    /// existing one can't fight over the same `fullScreenCover`.
    private struct WorkoutPresentation: Identifiable {
        let session: WorkoutSession
        let mode: ActiveWorkoutMode
        var id: PersistentIdentifier { session.persistentModelID }
    }

    private let calendar = Calendar.current
    private var unit: WeightUnit { settings.unit }

    private var sessionsByDay: [Date: [WorkoutSession]] {
        Dictionary(grouping: sessions.filter(\.isCompleted)) {
            calendar.startOfDay(for: $0.date)
        }
    }

    private var selectedSessions: [WorkoutSession] {
        (sessionsByDay[selectedDay] ?? []).sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthCard
                    dayDetail
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .background(Theme.surface)
            .navigationTitle("Calendar")
            .fullScreenCover(item: $presented) { presentation in
                ActiveWorkoutView(session: presentation.session,
                                  context: context,
                                  unit: unit,
                                  mode: presentation.mode)
            }
            .confirmationDialog("Delete this workout?",
                                isPresented: .init(get: { pendingDeletion != nil },
                                                   set: { if !$0 { pendingDeletion = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let session = pendingDeletion {
                        // Deleting a session cascades to its exercises and sets. Streaks
                        // and records recompute on their own — nothing is stored.
                        context.delete(session)
                        try? context.save()
                        Haptics.warning()
                    }
                    pendingDeletion = nil
                }
                Button("Keep it", role: .cancel) { pendingDeletion = nil }
            } message: {
                if let session = pendingDeletion {
                    Text("This permanently deletes \(session.displayName) from \(session.date.formatted(date: .abbreviated, time: .omitted)) and all \(session.totalSets) of its sets. This can't be undone.")
                }
            }
            .sheet(isPresented: $addingWorkout) {
                TemplatePickerSheet(templates: templates,
                                    sessions: sessions,
                                    unit: unit,
                                    initialDate: startTimeForSelectedDay()) { template, date in
                    addWorkout(template: template, on: date)
                }
            }
        }
    }

    // MARK: - Month grid

    private var monthCard: some View {
        VStack(spacing: 14) {
            HStack {
                monthButton(systemName: "chevron.left", months: -1, label: "Previous month")
                Spacer()
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(Theme.label(19, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                monthButton(systemName: "chevron.right", months: 1, label: "Next month")
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(Theme.label(12, weight: .heavy))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                      spacing: 4) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func monthButton(systemName: String, months: Int, label: String) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.2)) {
                visibleMonth = calendar.date(byAdding: .month, value: months, to: visibleMonth) ?? visibleMonth
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(Theme.accent)
                .bigTapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func dayCell(_ day: Date) -> some View {
        let workouts = sessionsByDay[day] ?? []
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)

        return Button {
            Haptics.selectionChanged()
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(Theme.label(16, weight: workouts.isEmpty ? .semibold : .black))
                    .foregroundStyle(isSelected ? .white : (workouts.isEmpty ? .secondary : .primary))
                Circle()
                    .fill(workouts.isEmpty ? .clear : (isSelected ? Color.white : Theme.accent))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isToday && !isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayAccessibilityLabel(day, workouts: workouts))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func dayAccessibilityLabel(_ day: Date, workouts: [WorkoutSession]) -> String {
        let dayText = day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        guard !workouts.isEmpty else { return "\(dayText), no workout" }
        let names = workouts.map(\.displayName).joined(separator: ", ")
        return "\(dayText), \(workouts.count) \(workouts.count == 1 ? "workout" : "workouts"): \(names)"
    }

    // MARK: - Selected day

    @ViewBuilder
    private var dayDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: selectedDay.formatted(.dateTime.weekday(.wide).month(.wide).day()))

            if selectedSessions.isEmpty {
                Text("No workout logged this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .cardBackground()
            } else {
                ForEach(selectedSessions) { session in
                    sessionCard(session)
                }
            }

            // The most contextual place to backdate: you're already looking at the day.
            if !isSelectedDayInFuture {
                Button {
                    Haptics.tap()
                    addingWorkout = true
                } label: {
                    Label(selectedSessions.isEmpty ? "Add a workout on this day"
                                                   : "Add another workout on this day",
                          systemImage: "plus")
                }
                .buttonStyle(BigButtonStyle(kind: selectedSessions.isEmpty ? .primary : .secondary,
                                            size: 16))
            }
        }
    }

    private var isSelectedDayInFuture: Bool {
        selectedDay > calendar.startOfDay(for: Date())
    }

    /// Same time of day as right now, on the selected date — so a workout logged the next
    /// morning lands at a plausible hour rather than midnight. Never in the future.
    private func startTimeForSelectedDay() -> Date {
        let now = Date()
        guard !calendar.isDateInToday(selectedDay) else { return now }
        let time = calendar.dateComponents([.hour, .minute], from: now)
        let candidate = calendar.date(bySettingHour: time.hour ?? 18,
                                      minute: time.minute ?? 0,
                                      second: 0,
                                      of: selectedDay) ?? selectedDay
        return min(candidate, now)
    }

    /// Opens in `.live` mode on purpose: a workout you're logging late is still one where
    /// you're finding out whether you beat last time, so it gets the ring, the celebration
    /// and the summary. Only *fixing* an already-logged workout stays silent.
    private func addWorkout(template: WorkoutTemplate, on date: Date) {
        let session = WorkoutSession(date: min(date, Date()), template: template)
        context.insert(session)
        try? context.save()
        presented = WorkoutPresentation(session: session, mode: .live)
    }

    private func sessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayName)
                        .font(Theme.label(20, weight: .black))
                    Text(session.date.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ScorePill(score: VolumeScore.score(for: session, in: unit), prominent: true)
            }

            ForEach(session.entriesSorted) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.displayName)
                            .font(Theme.label(16, weight: .bold))
                        Spacer()
                        Text(VolumeScore.format(VolumeScore.score(for: entry, in: unit)))
                            .font(Theme.label(15, weight: .heavy))
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                    }
                    Text(entry.setsSorted.map(setSummary).joined(separator: "   ·   "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 10) {
                Button {
                    presented = WorkoutPresentation(session: session, mode: .editingPast)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(BigButtonStyle(kind: .secondary, size: 16))

                Button(role: .destructive) {
                    pendingDeletion = session
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(BigButtonStyle(kind: .destructive, size: 16))
                .accessibilityLabel("Delete \(session.displayName) workout")
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func setSummary(_ set: SetEntry) -> String {
        guard let value = set.weight(in: unit), value > 0 else { return "\(set.reps)" }
        let weight = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return "\(set.reps)×\(weight)"
    }

    // MARK: - Grid maths

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var monthCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstDay = interval.start
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        return cells
    }
}
