import SwiftUI

struct TransactionSummaryCard: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date

    var body: some View {
        HStack(spacing: 0) {
            // 收入
            VStack(spacing: 3) {
                Text(LocalizedString("income"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(dataManager.getTotalIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 1, height: 35)

            // 支出
            VStack(spacing: 3) {
                Text(LocalizedString("expense"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(dataManager.getTotalExpense(for: period, customStartDate: customStartDate, customEndDate: customEndDate)))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 1, height: 35)

            // 结余
            VStack(spacing: 3) {
                Text(LocalizedString("surplus"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                let balance = dataManager.getBalance(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
                Text(formatCurrency(balance))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(balance >= 0 ? .green : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}