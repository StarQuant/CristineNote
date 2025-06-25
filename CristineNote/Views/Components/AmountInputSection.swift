import SwiftUI

struct AmountInputSection: View {
    @Binding var amount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("amount"))
                .font(.system(.headline, weight: .semibold))

            HStack {
                Text("¥")
                    .font(.system(.title, weight: .medium))
                    .foregroundColor(.secondary)

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