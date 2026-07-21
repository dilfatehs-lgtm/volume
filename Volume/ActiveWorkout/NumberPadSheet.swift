import SwiftUI

/// A deliberately huge number pad.
///
/// The system keyboard is small, appears at the bottom, and shifts the layout. This
/// doesn't: every key is at least 64pt tall and the value being edited stays in view.
struct NumberPadSheet: View {

    let title: String
    var suffix: String?
    var allowsDecimal = false
    let initialValue: Double
    let onCommit: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    private var parsedValue: Double {
        Double(text) ?? 0
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(Theme.label(13, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(text.isEmpty ? "0" : text)
                        .font(Theme.numeral(60))
                        .monospacedDigit()
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    if let suffix {
                        Text(suffix)
                            .font(Theme.label(20, weight: .heavy))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(text.isEmpty ? "empty" : text)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(keyRows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            keyButton(key)
                        }
                    }
                }
            }

            Button("Done") {
                onCommit(parsedValue)
                Haptics.tap()
                dismiss()
            }
            .buttonStyle(.big)
            .padding(.top, 4)
        }
        .padding(Theme.gutter)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
        .onAppear {
            text = Self.initialText(initialValue, allowsDecimal: allowsDecimal)
        }
    }

    private var keyRows: [[String]] {
        [["1", "2", "3"],
         ["4", "5", "6"],
         ["7", "8", "9"],
         [allowsDecimal ? "." : "clear", "0", "delete"]]
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        Button {
            Haptics.tap()
            handle(key)
        } label: {
            Group {
                switch key {
                case "delete": Image(systemName: "delete.left.fill").font(.system(size: 24, weight: .bold))
                case "clear": Text("C").font(Theme.numeral(26))
                default: Text(key).font(Theme.numeral(30))
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.cardRaised))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    private func accessibilityLabel(for key: String) -> String {
        switch key {
        case "delete": "Delete last digit"
        case "clear": "Clear"
        case ".": "Decimal point"
        default: key
        }
    }

    private func handle(_ key: String) {
        switch key {
        case "delete":
            if !text.isEmpty { text.removeLast() }
        case "clear":
            text = ""
        case ".":
            guard allowsDecimal, !text.contains(".") else { return }
            text = text.isEmpty ? "0." : text + "."
        default:
            // Cap the length so a stray press can't produce an absurd number.
            guard text.replacingOccurrences(of: ".", with: "").count < 5 else { return }
            if text == "0" { text = key } else { text += key }
        }
    }

    private static func initialText(_ value: Double, allowsDecimal: Bool) -> String {
        guard value > 0 else { return "" }
        if allowsDecimal, value != value.rounded() {
            return String(format: "%.1f", value)
        }
        return String(Int(value.rounded()))
    }
}

#Preview {
    NumberPadSheet(title: "Weight", suffix: "lb", allowsDecimal: true, initialValue: 135) { _ in }
}
