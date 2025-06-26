import SwiftUI

struct TransactionDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部金额显示
                    VStack(spacing: 8) {
                        Circle()
                            .fill(transaction.category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: transaction.category.iconName)
                                    .foregroundColor(transaction.category.color)
                                    .font(.system(size: 32, weight: .medium))
                            )
                        
                        Text(transaction.displayAmount)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(transaction.type == .income ? .green : .red)
                        
                        Text(transaction.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 详细信息卡片
                    VStack(spacing: 0) {
                        // 分类
                        DetailRowView(
                            title: LocalizedString("category"),
                            content: transaction.category.displayName(for: dataManager),
                            icon: "folder.fill"
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        // 日期
                        DetailRowView(
                            title: LocalizedString("date"),
                            content: formatDate(transaction.date),
                            icon: "calendar"
                        )
                        
                        if !transaction.note.isEmpty {
                            Divider()
                                .padding(.leading, 44)
                            
                            // 备注
                            DetailRowView(
                                title: LocalizedString("note"),
                                content: transaction.note,
                                icon: "note.text",
                                isMultiLine: true
                            )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle(LocalizedString("transaction_detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if LocalizationManager.shared.currentLanguage == "zh-Hans" {
            formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        } else {
            formatter.dateFormat = "MMM dd, yyyy HH:mm"
        }
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US")
        return formatter.string(from: date)
    }
}

struct DetailRowView: View {
    let title: String
    let content: String
    let icon: String
    var isMultiLine: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiLine ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(isMultiLine ? nil : 1)
                    .fixedSize(horizontal: false, vertical: isMultiLine)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
} 