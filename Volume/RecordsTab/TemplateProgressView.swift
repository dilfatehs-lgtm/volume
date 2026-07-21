import Charts
import SwiftUI

/// One workout's scores over time.
///
/// Always scoped to a single workout, which is what the old "All" filter could never be —
/// mixing Legs at 15,000 with Arms at 4,000 produced a jagged line that meant nothing.
/// Still just the line: no trend analysis, no projections, no advice.
struct TemplateProgressView: View {

    let record: TemplateRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headline

                if record.points.count < 2 {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "One workout in",
                                   message: "Log \(record.name) once more and the line starts.")
                        .cardBackground()
                } else {
                    chart
                    Text("\(record.sessionCount) workouts logged")
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

    private var chart: some View {
        Chart(record.points) { point in
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
        guard let first = record.points.first, let last = record.points.last else { return "No data" }
        return """
            \(record.points.count) workouts from \(first.date.formatted(date: .abbreviated, time: .omitted)) \
            to \(last.date.formatted(date: .abbreviated, time: .omitted)). \
            First \(VolumeScore.format(first.score)), latest \(VolumeScore.format(last.score)), \
            best \(VolumeScore.format(record.bestScore)).
            """
    }
}
