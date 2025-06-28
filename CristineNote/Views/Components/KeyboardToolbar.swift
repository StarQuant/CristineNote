import SwiftUI

// 键盘收起按钮 ViewModifier - 避免约束冲突  
struct KeyboardToolbar: ViewModifier {
    @State private var isKeyboardVisible = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            
            if isKeyboardVisible {
                Button(action: hideKeyboard) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(radius: 2)
                        )
                }
                .padding(.trailing, 16)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isKeyboardVisible = false
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), 
            to: nil, 
            from: nil, 
            for: nil
        )
    }
}

// 便捷方法
extension View {
    func keyboardToolbar() -> some View {
        modifier(KeyboardToolbar())
    }
} 