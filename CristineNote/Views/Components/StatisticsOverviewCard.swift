import SwiftUI

struct StatisticsOverviewCard: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?

    var body: some View {
        VStack(spacing: 16) {
            // 根据选择的类型显示对应的统计项
            if selectedType == nil {
                // 全部模式：垂直显示三个统计项
                VStack(spacing: 8) {
                    StatisticRowItem(
                        title: LocalizedString("income"),
                        value: formatCurrency(getIncomeAmount()),
                        color: .green
                    )
                    
                    StatisticRowItem(
                        title: LocalizedString("expense"),
                        value: formatCurrency(getExpenseAmount()),
                        color: .red
                    )
                    
                    StatisticRowItem(
                        title: LocalizedString("surplus"),
                        value: formatCurrency(getBalanceAmount()),
                        color: getBalanceAmount() >= 0 ? .green : .red
                    )
                }
            } else if selectedType == .income {
                // 收入模式：只显示收入
                StatisticRowItem(
                    title: LocalizedString("income"),
                    value: formatCurrency(getIncomeAmount()),
                    color: .green
                )
            } else {
                // 支出模式：只显示支出
                StatisticRowItem(
                    title: LocalizedString("expense"),
                    value: formatCurrency(getExpenseAmount()),
                    color: .red
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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

struct StatisticItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(.title3, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatisticRowItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: getIconName())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            // 文字内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private func getIconName() -> String {
        switch title {
        case LocalizedString("income"):
            return "arrow.down.circle.fill"
        case LocalizedString("expense"):
            return "arrow.up.circle.fill"
        case LocalizedString("surplus"):
            return "wallet.pass.fill"
        default:
            return "circle.fill"
        }
    }
}