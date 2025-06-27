import SwiftUI

struct MainTabView: View {
    @StateObject private var dataManager = DataManager()
    @StateObject private var translationService = TranslationService()
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    LocalizedText("home")
                }
                .environmentObject(dataManager)
                .environmentObject(translationService)
                .environmentObject(localizationManager)

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    LocalizedText("statistics")
                }
                .environmentObject(dataManager)
                .environmentObject(translationService)
                .environmentObject(localizationManager)

            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    LocalizedText("categories")
                }
                .environmentObject(dataManager)
                .environmentObject(translationService)
                .environmentObject(localizationManager)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    LocalizedText("settings")
                }
                .environmentObject(translationService)
                .environmentObject(dataManager)
                .environmentObject(localizationManager)
        }
        .accentColor(.blue)
        .onAppear {
            // 确保TabBar背景正常显示，与其他页面保持一致
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}