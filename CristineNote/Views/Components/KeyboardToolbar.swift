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

// 独立的键盘收起按钮组件
struct KeyboardDismissButton: View {
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        if keyboardObserver.isVisible {
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
            .transition(.opacity.combined(with: .scale))
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

// 键盘状态监听器 - 全局共享
class KeyboardObserver: ObservableObject {
    @Published var isVisible = false
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self?.isVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self?.isVisible = false
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// 便捷方法
extension View {
    func keyboardToolbar() -> some View {
        modifier(KeyboardToolbar())
    }
} 