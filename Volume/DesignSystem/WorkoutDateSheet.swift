import SwiftUI

/// How a workout's date and time are shown and edited.
///
/// People log on the couch, not at the rack. Without this, a workout done on Saturday and
/// logged on Monday lands on the wrong day — which quietly corrupts both the calendar and
/// the distinct-days count behind the week streak.
enum WorkoutDateLabel {

    /// "Now · 6:30 PM", "Today · 8:15 AM", "Yesterday · 7:00 PM", "Sat, Jul 18 · 6:30 PM".
    static func text(for date: Date,
                     now: Date = Date(),
                     calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if abs(date.timeIntervalSince(now)) < 120 { return "Now · \(time)" }
        if calendar.isDateInToday(date) { return "Today · \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday · \(time)" }
        let day = date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return "\(day) · \(time)"
    }

    /// True when the date is far enough from now to be worth pointing out.
    static func isBackdated(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        !calendar.isDateInToday(date)
    }
}

/// Tappable row showing when a workout happened.
struct WorkoutDateRow: View {

    let date: Date
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.accent)

                Text(WorkoutDateLabel.text(for: date))
                    .font(Theme.label(17, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(minHeight: Theme.minTapTarget)
            .cardBackground()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Workout date and time")
        .accessibilityValue(WorkoutDateLabel.text(for: date))
        .accessibilityHint("Change when this workout happened")
    }
}

struct WorkoutDateSheet: View {

    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    /// Captured once so the picker's bound doesn't drift while the sheet is open.
    @State private var latestAllowed = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Future workouts aren't a thing, and allowing them would scramble the
                // date ordering that every score-to-beat comparison depends on.
                DatePicker("When did this workout happen?",
                           selection: $date,
                           in: ...latestAllowed,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(Theme.accent)

                Button("Set to now") {
                    Haptics.tap()
                    date = Date()
                }
                .buttonStyle(.bigSecondary)

                Spacer(minLength: 0)
            }
            .padding(Theme.gutter)
            .background(Theme.surface)
            .navigationTitle("When?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                latestAllowed = Date()
                if date > latestAllowed { date = latestAllowed }
            }
        }
        .presentationDetents([.large])
    }
}
