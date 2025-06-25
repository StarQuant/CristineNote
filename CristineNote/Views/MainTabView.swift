import SwiftUI

struct MainTabView: View {
    @StateObject private var dataManager = DataManager()
    @StateObject private var translationService = TranslationService()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    LocalizedText("home")
                }
                .environmentObject(dataManager)

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    LocalizedText("statistics")
                }
                .environmentObject(dataManager)

            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    LocalizedText("categories")
                }
                .environmentObject(dataManager)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    LocalizedText("settings")
                }
                .environmentObject(translationService)
                .environmentObject(dataManager)
        }
        .accentColor(.blue)
        .onAppear {
            // 智能检查并修复图标（只在需要时执行）
            dataManager.checkAndFixIconsIfNeeded()
        }
    }
}