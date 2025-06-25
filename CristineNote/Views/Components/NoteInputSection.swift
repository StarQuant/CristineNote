import SwiftUI

struct NoteInputSection: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("note"))
                .font(.system(.headline, weight: .semibold))

            TextField(LocalizedString("enter_note"), text: $note)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
}