import SwiftUI

// 基于开源最佳实践的键盘工具栏
// 注意：多行文本编辑时可能出现SystemInputAssistantView约束冲突警告
// 这是iOS系统级已知bug，不影响功能，可以安全忽略
struct KeyboardToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                // 浮动收起按钮，只在需要时显示
                KeyboardDismissButton()
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

// 简化的键盘收起按钮 - 避免所有状态管理问题
struct KeyboardDismissButton: View {
    var body: some View {
        // 始终显示的简单按钮，用户可以随时点击收起键盘
        Button(action: hideKeyboard) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.7))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
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