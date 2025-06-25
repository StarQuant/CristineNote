import SwiftUI

struct StatisticsOverviewCard: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatisticItem(
                    title: LocalizedString("income"),
                    value: formatCurrency(dataManager.getTotalIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)),
                    color: .green
                )

                StatisticItem(
                    title: LocalizedString("expense"),
                    value: formatCurrency(dataManager.getTotalExpense(for: period, customStartDate: customStartDate, customEndDate: customEndDate)),
                    color: .red
                )

                StatisticItem(
                    title: LocalizedString("surplus"),
                    value: formatCurrency(dataManager.getBalance(for: period, customStartDate: customStartDate, customEndDate: customEndDate)),
                    color: dataManager.getBalance(for: period, customStartDate: customStartDate, customEndDate: customEndDate) >= 0 ? .green : .red
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
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
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}