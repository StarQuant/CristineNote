import SwiftUI

struct CategoryTypeSelector: View {
    @Binding var selectedType: TransactionType
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: type.iconName)
                        Text(type == .expense ? LocalizedString("expense_categories") : LocalizedString("income_categories"))
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedType == type ? type.color : Color.clear
                    )
                    .foregroundColor(
                        selectedType == type ? .white : .primary
                    )
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}