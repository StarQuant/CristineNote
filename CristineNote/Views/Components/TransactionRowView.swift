import SwiftUI

struct TransactionRowView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var localizationManager: LocalizationManager
    let transaction: Transaction
    let showIcons: Bool // 是否显示图标
    
    init(transaction: Transaction, showIcons: Bool = false) {
        self.transaction = transaction
        self.showIcons = showIcons
    }

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
                    if showIcons {
                        HStack(spacing: 4) {
                            Text(transaction.category.displayName(for: dataManager))
                                .font(.system(.subheadline, weight: .medium))
                            
                            // 显示翻译图标（如果是翻译版本）
                            if transaction.isDisplayedNoteTranslated(localizationManager: localizationManager) {
                                TranslationIcon(size: 10)
                            }
                            
                            // 显示编辑图标（如果被编辑过）
                            if transaction.isEdited {
                                Image(systemName: "pencil")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                    } else {
                        Text(transaction.category.displayName(for: dataManager))
                            .font(.system(.subheadline, weight: .medium))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(dataManager.displayAmount(for: transaction))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundColor(transaction.type == .income ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        // 显示原始币种（如果与系统币种不同）
                        if transaction.originalCurrency != dataManager.currentSystemCurrency {
                            Text("(\(transaction.originalAmountText))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                HStack {
                    let displayNote = transaction.displayNote(localizationManager: localizationManager)
                    if !displayNote.isEmpty {
                        Text(displayNote)
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