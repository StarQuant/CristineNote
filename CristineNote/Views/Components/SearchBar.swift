import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(LocalizedString("search_transactions"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isTextFieldFocused)
                .onSubmit {
                    isTextFieldFocused = false
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        
    }
    

}