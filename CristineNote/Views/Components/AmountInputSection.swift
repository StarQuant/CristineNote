import SwiftUI

struct AmountInputSection: View {
    @Binding var amount: String
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("amount"))
                .font(.system(.headline, weight: .semibold))

            HStack {
                // 显示当前系统货币符号，不可选择
                Text(dataManager.currentSystemCurrency.symbol)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)

                TextField(LocalizedString("enter_amount"), text: $amount)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}