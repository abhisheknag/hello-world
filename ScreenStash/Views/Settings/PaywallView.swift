import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var purchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    termsSection
                }
                .padding()
            }
            .navigationTitle("ScreenStash Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Unlock Your Full Library")
                .font(.title2.bold())

            Text("Organize, search, and clean up every screenshot on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "infinity", color: .blue, text: "Unlimited screenshot processing")
            featureRow(icon: "text.magnifyingglass", color: .green, text: "Full-text search across all screenshots")
            featureRow(icon: "square.grid.2x2.fill", color: .orange, text: "All 10 smart categories")
            featureRow(icon: "doc.on.doc.fill", color: .purple, text: "Duplicate detection & cleanup")
            featureRow(icon: "trash.circle.fill", color: .red, text: "Bulk delete by category or date")
            featureRow(icon: "widget.small", color: .teal, text: "Home & Lock Screen widgets")
            featureRow(icon: "link", color: .indigo, text: "Open URLs, create contacts from screenshots")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Annual subscription — highlighted
            if let annual = subscriptionManager.annualProduct {
                Button {
                    Task { await purchase(annual) }
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Annual")
                                .font(.headline)
                            Spacer()
                            Text(annual.displayPrice + "/year")
                                .font(.headline)
                        }
                        HStack {
                            Text("3-day free trial")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("~\(monthlyPrice(from: annual))/month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(purchasing)
            }

            // Lifetime — secondary
            if let lifetime = subscriptionManager.lifetimeProduct {
                Button {
                    Task { await purchase(lifetime) }
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Lifetime")
                                .font(.headline)
                            Spacer()
                            Text(lifetime.displayPrice)
                                .font(.headline)
                        }
                        HStack {
                            Text("One-time purchase, forever")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(purchasing)
            }

            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.subheadline)
        }
    }

    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private func monthlyPrice(from product: Product) -> String {
        let monthly = product.price / 12
        return monthly.formatted(.currency(code: product.priceFormatStyle.currencyCode ?? "USD"))
    }

    private func purchase(_ product: Product) async {
        purchasing = true
        errorMessage = nil
        do {
            let transaction = try await subscriptionManager.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        purchasing = false
    }
}
