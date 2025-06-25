import SwiftUI

struct TransactionRowView: View {
    @EnvironmentObject var dataManager: DataManager
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            Circle()
                .fill(transaction.category.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: transaction.category.iconName)
                        .foregroundColor(transaction.category.color)
                        .font(.system(size: 16, weight: .medium))
                )

            // 交易信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.category.displayName(for: dataManager))
                        .font(.system(.subheadline, weight: .medium))

                    Spacer()

                    Text(transaction.displayAmount)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                HStack {
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(formatDate(transaction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = LocalizationManager.shared.currentLanguage == "zh-Hans" ? "MM/dd" : "MM/dd"
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US")
        return formatter.string(from: date)
    }
}