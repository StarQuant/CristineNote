import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth
    @State private var searchText = ""
    @State private var customStartDate = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate = Date()
    @State private var selectedType: TransactionType? = nil
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?
    @State private var selectedTransaction: Transaction?

    private var filteredTransactions: [Transaction] {
        let transactions = dataManager.getTransactions(for: selectedPeriod, customStartDate: customStartDate, customEndDate: customEndDate)

        var filtered = transactions
        
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }

        if searchText.isEmpty {
            return filtered.sorted { $0.date > $1.date }
        } else {
            return filtered.filter { transaction in
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.displayName(for: dataManager).localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.date > $1.date }
        }
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = LocalizationManager.shared.currentLanguage == "zh-Hans" ? "yyyy年MM月dd日" : "MMM dd, yyyy"
            return formatter.string(from: transaction.date)
        }

        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 收入/支出类型筛选器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: {
                        selectedType = nil
                    }) {
                        Text(LocalizedString("all"))
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(selectedType == nil ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedType == nil ? Color.blue : Color(.systemGray6))
                            )
                    }
                    
                    ForEach([TransactionType.expense, TransactionType.income], id: \.self) { type in
                        Button(action: {
                            selectedType = type
                        }) {
                            Text(type.displayName)
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundColor(selectedType == type ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedType == type ? type.color : Color(.systemGray6))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            // 周期选择器 - 调整为与类型选择器相同的滚动布局
            PeriodSelector(
                selectedPeriod: $selectedPeriod,
                customStartDate: $customStartDate,
                customEndDate: $customEndDate
            )
            .padding(.bottom, 12)

            // 搜索栏
            SearchBar(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // 统计概览
            CompactOverviewCard(
                period: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                selectedType: selectedType
            )
            .environmentObject(dataManager)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // 交易列表
            if filteredTransactions.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(groupedTransactions, id: \.0) { date, transactions in
                        Section(header: DateHeaderView(date: date)) {
                            ForEach(transactions) { transaction in
                                TransactionRowView(transaction: transaction)
                                    .onTapGesture {
                                        selectedTransaction = transaction
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let transaction = transactions[index]
                                    transactionToDelete = transaction
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    // 刷新数据
                    dataManager.loadData()
                }
            }
        }
        .navigationTitle(LocalizedString("transaction_records"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            // 确保导航栏背景正常显示
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
                .environmentObject(dataManager)
        }
        .alert(LocalizedString("delete_transaction"), isPresented: $showingDeleteAlert) {
            Button(LocalizedString("cancel"), role: .cancel) { 
                print("取消删除")
                transactionToDelete = nil
            }
            Button(LocalizedString("delete"), role: .destructive) {
                print("确认删除")
                if let transaction = transactionToDelete {
                    print("删除交易: \(transaction.id)")
                    dataManager.deleteTransaction(transaction)
                    print("删除完成")
                } else {
                    print("错误：transactionToDelete为nil")
                }
                transactionToDelete = nil
            }
        } message: {
            Text(LocalizedString("delete_transaction_message"))
        }
    }



}