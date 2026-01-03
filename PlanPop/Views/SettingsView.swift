//
//  SettingsView.swift
//  PlanPop
//
//  Settings and preferences screen
//

import SwiftUI

/// Settings screen with app preferences
struct SettingsView: View {
    @EnvironmentObject var viewModel: TaskViewModel

    // Sheet states
    @State private var showingCategoryManager = false
    @State private var showingPremiumInfo = false
    @State private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                List {
                    // Stats section
                    Section {
                        statsCard
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    // Categories section
                    Section("Categories") {
                        Button {
                            showingCategoryManager = true
                        } label: {
                            HStack {
                                Label("Manage Categories", systemImage: "folder.fill")
                                Spacer()
                                Text("\(viewModel.categories.count)/\(viewModel.settings.isPremium ? "∞" : "3")")
                                    .foregroundColor(Theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .foregroundColor(Theme.textPrimary)
                    }

                    // Notifications section
                    Section("Notifications") {
                        Toggle("Enable Reminders", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { newValue in
                                if newValue {
                                    requestNotificationPermission()
                                }
                                viewModel.settings.notificationsEnabled = newValue
                            }
                    }

                    // Theme section
                    Section("Appearance") {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            themeRow(theme)
                        }
                    }

                    // Premium section
                    Section {
                        Button {
                            showingPremiumInfo = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text(viewModel.settings.isPremium ? "Premium Active" : "Upgrade to Premium")
                                            .fontWeight(.semibold)
                                    }
                                    Text(viewModel.settings.isPremium ?
                                         "Thank you for your support!" :
                                         "Unlock all themes, unlimited categories, and more!")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                if !viewModel.settings.isPremium {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        .foregroundColor(Theme.textPrimary)
                    }

                    // About section
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Theme.textSecondary)
                        }

                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(Theme.textPrimary)
                    }

                    // Debug section (remove in production)
                    #if DEBUG
                    Section("Debug") {
                        Button("Add Sample Tasks") {
                            for task in Task.sampleTasks {
                                viewModel.addTask(task)
                            }
                        }

                        Button("Toggle Premium") {
                            viewModel.setPremiumStatus(!viewModel.settings.isPremium)
                        }

                        Button("Reset All Data", role: .destructive) {
                            PersistenceManager.shared.clearAllData()
                            viewModel.loadData()
                        }
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCategoryManager) {
                CategoryManagerView()
            }
            .sheet(isPresented: $showingPremiumInfo) {
                PremiumInfoView()
            }
            .onAppear {
                checkNotificationStatus()
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Current streak
                StatBox(
                    value: "\(viewModel.settings.currentStreak)",
                    label: "Current Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                // Longest streak
                StatBox(
                    value: "\(viewModel.settings.longestStreak)",
                    label: "Best Streak",
                    icon: "trophy.fill",
                    color: .yellow
                )

                // Total completed
                StatBox(
                    value: "\(viewModel.settings.totalTasksCompleted)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: Theme.success
                )
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Theme Row

    private func themeRow(_ theme: AppTheme) -> some View {
        Button {
            if !theme.isPremiumOnly || viewModel.settings.isPremium {
                viewModel.setTheme(theme)
            } else {
                showingPremiumInfo = true
            }
        } label: {
            HStack {
                // Theme color preview
                Circle()
                    .fill(Theme.colors(for: theme).primary)
                    .frame(width: 24, height: 24)

                Text(theme.displayName)

                if theme.isPremiumOnly && !viewModel.settings.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if viewModel.settings.themeName == theme.rawValue {
                    Image(systemName: "checkmark")
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .foregroundColor(Theme.textPrimary)
    }

    // MARK: - Helpers

    private func requestNotificationPermission() {
        NotificationManager.shared.requestPermission { granted in
            notificationsEnabled = granted
        }
    }

    private func checkNotificationStatus() {
        NotificationManager.shared.checkPermissionStatus { granted in
            notificationsEnabled = granted && viewModel.settings.notificationsEnabled
        }
    }
}

// MARK: - Stat Box Component

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Info View

struct PremiumInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel
    @ObservedObject private var storeManager = StoreManager.shared

    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 40)

                Text("PlanPop Premium")
                    .font(.title)
                    .fontWeight(.bold)

                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    PremiumFeatureRow(icon: "paintpalette.fill", text: "All color themes")
                    PremiumFeatureRow(icon: "folder.fill", text: "Unlimited categories")
                    PremiumFeatureRow(icon: "star.fill", text: "Custom task icons")
                    PremiumFeatureRow(icon: "heart.fill", text: "Support indie development")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Price display
                if let product = storeManager.premiumProduct {
                    VStack(spacing: 4) {
                        Text("One-time purchase")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.primary)
                    }
                }

                // Purchase button
                Button {
                    _Concurrency.Task {
                        await storeManager.purchasePremium()
                    }
                } label: {
                    HStack {
                        if storeManager.purchaseState == .purchasing ||
                           storeManager.purchaseState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(purchaseButtonTitle)
                    }
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 24)
                .disabled(isPurchaseDisabled)

                // Restore purchases
                Button("Restore Purchases") {
                    _Concurrency.Task {
                        await storeManager.restorePurchases()
                    }
                }
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .disabled(storeManager.purchaseState == .loading)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: storeManager.purchaseState) { newState in
                handlePurchaseStateChange(newState)
            }
            .onChange(of: storeManager.isPremiumPurchased) { isPurchased in
                if isPurchased {
                    viewModel.setPremiumStatus(true)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    storeManager.resetState()
                    if storeManager.isPremiumPurchased {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .task {
                // Ensure products are loaded
                if storeManager.premiumProduct == nil {
                    await storeManager.loadProducts()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var purchaseButtonTitle: String {
        switch storeManager.purchaseState {
        case .purchasing:
            return "Purchasing..."
        case .loading:
            return "Loading..."
        case .purchased:
            return "Purchased!"
        case .pending:
            return "Pending..."
        default:
            if viewModel.settings.isPremium {
                return "Already Premium"
            }
            return "Unlock Premium - \(storeManager.priceString)"
        }
    }

    private var isPurchaseDisabled: Bool {
        switch storeManager.purchaseState {
        case .purchasing, .loading, .pending:
            return true
        default:
            return viewModel.settings.isPremium || storeManager.premiumProduct == nil
        }
    }

    // MARK: - State Handling

    private func handlePurchaseStateChange(_ state: PurchaseState) {
        switch state {
        case .purchased:
            alertTitle = "Thank You!"
            alertMessage = "You now have access to all premium features."
            showingAlert = true

        case .failed(let message):
            alertTitle = "Purchase Failed"
            alertMessage = message
            showingAlert = true

        case .pending:
            alertTitle = "Purchase Pending"
            alertMessage = "Your purchase is awaiting approval."
            showingAlert = true

        default:
            break
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(TaskViewModel())
}
