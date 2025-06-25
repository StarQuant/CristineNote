import SwiftUI

struct BottomActionButtons: View {
    let onSave: () -> Void
    let onCancel: () -> Void
    let isValid: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSave) {
                Text(LocalizedString("save"))
                    .font(.system(.headline, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isValid ? Color.blue : Color(.systemGray4))
                    )
                    .foregroundColor(.white)
            }
            .disabled(!isValid)

            Button(action: onCancel) {
                Text(LocalizedString("cancel"))
                    .font(.system(.headline, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}