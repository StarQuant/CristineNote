import SwiftUI

struct CategoryRowView: View {
    @EnvironmentObject var dataManager: DataManager
    let category: TransactionCategory

    var body: some View {
        HStack(spacing: 16) {
            // 分类图标
            Circle()
                .fill(category.color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                        .font(.system(size: 18, weight: .medium))
                )

            // 分类信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName(for: dataManager))
                    .font(.system(.headline, weight: .medium))

                Text(category.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 拖拽指示器
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}