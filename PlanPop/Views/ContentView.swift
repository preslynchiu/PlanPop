//
//  ContentView.swift
//  PlanPop
//
//  Main container view with tab navigation
//

import SwiftUI

/// Main app container with tab bar navigation
struct ContentView: View {
    // Shared view model
    @StateObject private var viewModel = TaskViewModel()

    // Currently selected tab
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tasks tab
            TaskListView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks")
                }
                .tag(0)

            // Settings tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(1)
        }
        .tint(Theme.primary)
        .environmentObject(viewModel)
        .confetti(isShowing: $viewModel.showConfetti)
        .alert("Achievement Unlocked!", isPresented: .init(
            get: { viewModel.newlyUnlockedAchievement != nil },
            set: { if !$0 { viewModel.clearNewlyUnlockedAchievement() } }
        )) {
            Button("Awesome!", role: .cancel) {
                viewModel.clearNewlyUnlockedAchievement()
            }
        } message: {
            if let achievement = viewModel.newlyUnlockedAchievement {
                Text("\(achievement.name)\n\(achievement.description)")
            }
        }
        .task {
            // Initialize StoreManager and sync premium status on launch
            await StoreManager.shared.updatePurchasedStatus()
            if StoreManager.shared.isPremiumPurchased {
                viewModel.setPremiumStatus(true)
            }
        }
        .onAppear {
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
