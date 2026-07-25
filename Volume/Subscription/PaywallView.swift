import StoreKit
import SwiftUI

struct PaywallView: View {

    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AppSettings.self) private var settings

    @State private var selectedID = SubscriptionManager.annualID
    @State private var trialAvailable = false

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            // Tight enough that both plans sit above the fold on the smallest supported
            // iPhone. A paywall where the cheaper option is hidden below a scroll isn't
            // offering a choice.
            ScrollView {
                VStack(spacing: 18) {
                    header
                    valueProps
                    PlanPicker(selectedID: $selectedID)
                    Color.clear.frame(height: 4)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .safeAreaInset(edge: .bottom) {
                PurchaseFooter(selectedID: selectedID, trialAvailable: trialAvailable)
            }
        }
        .task {
            // Retry a failed catalog load every time the paywall appears — without this,
            // one bad launch leaves a permanently empty paywall (App Review hit exactly
            // that on the resubscribe screen). Must run before the eligibility check,
            // which needs a loaded product.
            await subscriptions.ensureProductsLoaded()
            if let annual = subscriptions.annual {
                trialAvailable = await subscriptions.isEligibleForTrial(annual)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Theme.accentGradient)

            Text("Track volume.\nBeat your score.\nThat's it.")
                .font(Theme.label(29, weight: .black))
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var valueProps: some View {
        VStack(alignment: .leading, spacing: 11) {
            prop("number.circle.fill", "One number per workout",
                 "Every rep and plate adds up to a single score.")
            prop("flame.fill", "A target every session",
                 "Last time's score, waiting to be beaten.")
            prop("icloud.fill", "On all your devices",
                 "Synced with your iCloud. No account to make.")
        }
        .padding(14)
        .cardBackground()
    }

    private func prop(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.label(17, weight: .heavy))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Plan picker

struct PlanPicker: View {

    @Binding var selectedID: String
    @Environment(SubscriptionManager.self) private var subscriptions

    var body: some View {
        VStack(spacing: 10) {
            if subscriptions.products.isEmpty {
                unavailableNotice
            } else {
                ForEach(subscriptions.products, id: \.id) { product in
                    planRow(product)
                }
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        let isSelected = product.id == selectedID
        return Button {
            Haptics.selectionChanged()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedID = product.id
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.accent : .secondary)

                // Price above name, at the weight the name used to have: guideline
                // 3.1.2(c) requires the billed amount to be the most conspicuous
                // pricing element on the screen.
                VStack(alignment: .leading, spacing: 2) {
                    Text(priceLine(product))
                        .font(Theme.label(19, weight: .heavy))
                    Text(product.id == SubscriptionManager.annualID ? "Yearly" : "Monthly")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let badge = savingsBadge(product) {
                    Text(badge)
                        .font(Theme.label(12, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentGradient))
                }
            }
            .padding(14)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Theme.hairline,
                                  lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(product.id == SubscriptionManager.annualID ? "Yearly" : "Monthly"), \(product.displayPrice)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func priceLine(_ product: Product) -> String {
        if product.id == SubscriptionManager.annualID {
            return "\(product.displayPriceWithCurrency) a year"
        }
        return "\(product.displayPriceWithCurrency) a month"
    }

    /// Only shown when both prices are known, so it can never be a made-up number.
    private func savingsBadge(_ product: Product) -> String? {
        guard product.id == SubscriptionManager.annualID,
              let monthly = subscriptions.monthly else { return nil }
        let yearOfMonthly = monthly.price * 12
        guard yearOfMonthly > 0, product.price < yearOfMonthly else { return nil }
        let saved = (yearOfMonthly - product.price) / yearOfMonthly * 100
        return "SAVE \(Int(NSDecimalNumber(decimal: saved).doubleValue.rounded()))%"
    }

    private var unavailableNotice: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.secondary)
            Text("Prices couldn't be loaded")
                .font(Theme.label(17, weight: .heavy))
            Text("Check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await subscriptions.refresh() }
            }
            .buttonStyle(BigButtonStyle(kind: .secondary, size: 16))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }
}

// MARK: - Footer

struct PurchaseFooter: View {

    let selectedID: String
    var trialAvailable: Bool

    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AppSettings.self) private var settings

    private var product: Product? {
        subscriptions.products.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(spacing: 10) {
            Button {
                guard let product else { return }
                Task { await subscriptions.purchase(product) }
            } label: {
                if subscriptions.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    // Never "Try free for 7 days": the CTA leading with the trial is what
                    // guideline 3.1.2(c) rejects. The trial lives in the fineprint below.
                    Text("Subscribe")
                }
            }
            .buttonStyle(.big)
            .disabled(product == nil || subscriptions.isWorking)

            Text(fineprint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let error = subscriptions.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 18) {
                Button("Restore") {
                    Task { await subscriptions.restore() }
                }
                .disabled(subscriptions.isWorking)
                Link("Terms", destination: LegalLinks.terms)
                Link("Privacy", destination: LegalLinks.privacy)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(minHeight: 44)

            #if DEBUG
            Button("Skip paywall (DEBUG)") {
                settings.debugUnlocked = true
            }
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .frame(minHeight: 36)
            #endif
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(.bar)
    }

    /// The billed amount leads the sentence and the trial is a subordinate clause —
    /// the order is part of the 3.1.2(c) fix, not a style choice.
    private var fineprint: String {
        guard let product else { return "Subscription renews automatically. Cancel any time." }
        let period = product.id == SubscriptionManager.annualID ? " a year" : " a month"
        let price = "\(product.displayPriceWithCurrency)\(period)"
        if trialAvailable {
            return "\(price) after a 7-day free trial. Cancel any time."
        }
        return "\(price). Cancel any time."
    }
}

/// Published from `docs/` in this repo via GitHub Pages. App Review rejects
/// auto-renewable subscriptions whose Terms and Privacy links don't load, so these must
/// stay live and must match what's entered in App Store Connect.
enum LegalLinks {
    static let terms = URL(string: "https://dilfatehs-lgtm.github.io/volume/terms.html")!
    static let privacy = URL(string: "https://dilfatehs-lgtm.github.io/volume/privacy.html")!
    static let support = URL(string: "https://dilfatehs-lgtm.github.io/volume/")!
}
