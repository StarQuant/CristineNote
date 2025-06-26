import SwiftUI

struct StatisticsCompactOverviewCard: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?

    var body: some View {
        VStack(spacing: 14) {
            // 根据选择的类型显示主要统计
            if selectedType == nil {
                // 全部模式：显示净收入/结余
                VStack(spacing: 4) {
                    Text(LocalizedString("surplus"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let balance = getBalanceAmount()
                    Text(formatCurrency(balance))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(balance >= 0 ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                // 收入支出对比
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(LocalizedString("income"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(getIncomeAmount()))
                            .font(.system(.title3, weight: .semibold))
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(LocalizedString("expense"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(getExpenseAmount()))
                            .font(.system(.title3, weight: .semibold))
                            .foregroundColor(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else if selectedType == .income {
                // 收入模式：只显示收入
                VStack(spacing: 4) {
                    Text(LocalizedString("income"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(getIncomeAmount()))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else {
                // 支出模式：只显示支出
                VStack(spacing: 4) {
                    Text(LocalizedString("expense"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(getExpenseAmount()))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
    }
    
    private func getIncomeAmount() -> Double {
        if let type = selectedType {
            return type == .income ? dataManager.getTotalIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate) : 0
        } else {
            return dataManager.getTotalIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
        }
    }
    
    private func getExpenseAmount() -> Double {
        if let type = selectedType {
            return type == .expense ? dataManager.getTotalExpense(for: period, customStartDate: customStartDate, customEndDate: customEndDate) : 0
        } else {
            return dataManager.getTotalExpense(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
        }
    }
    
    private func getBalanceAmount() -> Double {
        return getIncomeAmount() - getExpenseAmount()
    }

    private func formatCurrency(_ amount: Double) -> String {
        return CristineNote.formatCurrency(amount, currency: dataManager.currentSystemCurrency)
    }
} 