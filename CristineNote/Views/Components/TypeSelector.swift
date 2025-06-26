import SwiftUI

struct TypeSelector: View {
    @Binding var selectedType: TransactionType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .font(.system(.subheadline, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedType == type ? type.color : Color(.systemGray5)
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