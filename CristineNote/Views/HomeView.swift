import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingAddTransaction = false
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部概览卡片
                        OverviewCard(period: selectedPeriod)
                            .environmentObject(dataManager)

                        // 周期选择器
                        HomePeriodSelector(selectedPeriod: $selectedPeriod)

                        // 最近交易
                        RecentTransactionsSection()
                            .environmentObject(dataManager)
                            .environmentObject(translationService)
                            .environmentObject(localizationManager)
                    }
                    .padding()
                    .padding(.top, 8) // 为浮动按钮留出空间
                }

                // 顶部右侧浮动快速添加按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddTransaction = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .environmentObject(dataManager)
                    .environmentObject(translationService)
                    .environmentObject(localizationManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // 确保在iPad上也使用栈式导航
    }
}