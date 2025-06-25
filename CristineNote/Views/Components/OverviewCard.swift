import SwiftUI

struct OverviewCard: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod

    var body: some View {
        VStack(spacing: 16) {
            // 余额
            VStack(spacing: 4) {
                Text(LocalizedString("net_income"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                let balance = dataManager.getBalance(for: period)
                Text(formatCurrency(balance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
                    Text(formatCurrency(dataManager.getTotalIncome(for: period)))
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
                    Text(formatCurrency(dataManager.getTotalExpense(for: period)))
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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