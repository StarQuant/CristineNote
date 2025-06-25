import SwiftUI

struct CategoryButton: View {
    @EnvironmentObject var dataManager: DataManager
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(category.color.opacity(isSelected ? 1 : 0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: category.iconName)
                            .foregroundColor(isSelected ? .white : category.color)
                            .font(.system(size: 16, weight: .medium))
                    )

                Text(category.displayName(for: dataManager))
                    .font(.system(.caption, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1)
            )
        }
    }
}