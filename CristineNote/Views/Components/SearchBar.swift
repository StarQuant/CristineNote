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
                    hideKeyboard()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(action: {
                            hideKeyboard()
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                    }
                }
                .onAppear {
                    // 设置键盘工具栏透明
                    let appearance = UIToolbar.appearance(whenContainedInInstancesOf: [UINavigationController.self])
                    appearance.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
                    appearance.setShadowImage(UIImage(), forToolbarPosition: .any)
                    appearance.backgroundColor = .clear
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
    
    private func hideKeyboard() {
        isTextFieldFocused = false
    }
}