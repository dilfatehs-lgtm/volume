import Charts
import SwiftUI

/// One workout's scores over time.
///
/// Always scoped to a single workout, which is what the old "All" filter could never be —
/// mixing Legs at 15,000 with Arms at 4,000 produced a jagged line that meant nothing.
/// Still just the line: no trend analysis, no projections, no advice.
struct TemplateProgressView: View {

    let record: TemplateRecord

    @State private var range: ChartRange = .all

    enum ChartRange: String, CaseIterable, Identifiable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case all = "All"

        var id: String { rawValue }

        var months: Int? {
            switch self {
            case .threeMonths: 3
            case .sixMonths: 6
            case .year: 12
            case .all: nil
            }
        }
    }

    /// Points inside the selected window. Falls back to everything rather than showing an
    /// empty chart when a short range contains fewer than two workouts.
    private var visiblePoints: [ScorePoint] {
        guard let months = range.months,
              let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date())
        else { return record.points }
        let windowed = record.points.filter { $0.date >= cutoff }
        return windowed.count >= 2 ? windowed : record.points
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headline

                if record.points.count >= 2 {
                    rangePicker
                }

                if record.points.count < 2 {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "One workout in",
                                   message: "Log \(record.name) once more and the line starts.")
                        .cardBackground()
                } else {
                    chart
                    Text(visiblePoints.count == record.points.count
                         ? "\(record.sessionCount) workouts logged"
                         : "\(visiblePoints.count) of \(record.sessionCount) workouts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .background(Theme.surface)
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headline: some View {
        HStack(spacing: 12) {
            stat(title: "Best", value: record.bestScore,
                 caption: record.bestDate.formatted(.dateTime.month().day()),
                 highlighted: true)
            stat(title: "Last", value: record.lastScore,
                 caption: record.lastDate.formatted(.dateTime.month().day()),
                 highlighted: false)
        }
    }

    private func stat(title: String, value: Double, caption: String, highlighted: Bool) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(Theme.label(11, weight: .heavy))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(VolumeScore.format(value))
                .font(Theme.numeral(30))
                .monospacedDigit()
                .foregroundStyle(highlighted ? AnyShapeStyle(Theme.accentGradient)
                                             : AnyShapeStyle(Color.primary))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }

    private var rangePicker: some View {
        Picker("Time range", selection: $range) {
            ForEach(ChartRange.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Time range")
    }

    private var chart: some View {
        Chart(visiblePoints) { point in
            AreaMark(x: .value("Date", point.date),
                     y: .value("Score", point.score))
                .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.35), .clear],
                                                startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)

            LineMark(x: .value("Date", point.date),
                     y: .value("Score", point.score))
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)

            PointMark(x: .value("Date", point.date),
                      y: .value("Score", point.score))
                .foregroundStyle(Theme.accent)
                .symbolSize(58)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text(VolumeScore.format(score))
                    }
                }
            }
        }
        .frame(height: 260)
        .padding(.top, 8)
        // Room for the last date label to sit under its gridline without being clipped.
        .padding(.trailing, 14)
        .padding(16)
        .cardBackground()
        .accessibilityLabel("\(record.name) volume score over time")
        .accessibilityValue(chartAccessibilityValue)
    }

    private var chartAccessibilityValue: String {
        guard let first = visiblePoints.first, let last = visiblePoints.last else { return "No data" }
        return """
            \(visiblePoints.count) workouts from \(first.date.formatted(date: .abbreviated, time: .omitted)) \
            to \(last.date.formatted(date: .abbreviated, time: .omitted)). \
            First \(VolumeScore.format(first.score)), latest \(VolumeScore.format(last.score)), \
            best \(VolumeScore.format(record.bestScore)).
            """
    }
}
