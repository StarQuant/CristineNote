import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth
    @State private var searchText = ""
    @State private var customStartDate = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate = Date()
    @State private var selectedType: TransactionType? = nil

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
            // 顶部统计卡片
            TransactionSummaryCard(
                period: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
            .environmentObject(dataManager)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // 收入/支出类型筛选器 - 移到顶部
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
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // 周期选择器 - 移到类型选择器下方，左对齐
            HStack {
                PeriodSelector(
                    selectedPeriod: $selectedPeriod,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // 搜索栏
            SearchBar(text: $searchText)
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
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                deleteTransactions(at: indexSet, from: transactions)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    // 刷新数据
                    dataManager.loadData()
                }
            }
        }
        .navigationTitle(LocalizedString("transaction_records"))
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            // 点击空白处收回键盘
            hideKeyboard()
        }
    }

    private func deleteTransactions(at offsets: IndexSet, from transactions: [Transaction]) {
        for index in offsets {
            dataManager.deleteTransaction(transactions[index])
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}