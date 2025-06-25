import SwiftUI

// 响应式本地化Text组件
struct LocalizedText: View {
    private let key: String
    private let comment: String
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init(_ key: String, comment: String = "") {
        self.key = key
        self.comment = comment
    }

    var body: some View {
        Text(localizationManager.localizedString(for: key, comment: comment))
    }
}

// 响应式本地化Button标题
struct LocalizedButton: View {
    private let titleKey: String
    private let action: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init(_ titleKey: String, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.action = action
    }

    var body: some View {
        Button(localizationManager.localizedString(for: titleKey), action: action)
    }
}

// 响应式本地化TextField
struct LocalizedTextField: View {
    private let titleKey: String
    @Binding private var text: String
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init(_ titleKey: String, text: Binding<String>) {
        self.titleKey = titleKey
        self._text = text
    }

    var body: some View {
        TextField(localizationManager.localizedString(for: titleKey), text: $text)
    }
}

// 响应式本地化NavigationTitle
struct LocalizedNavigationTitle: ViewModifier {
    private let titleKey: String
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init(_ titleKey: String) {
        self.titleKey = titleKey
    }

    func body(content: Content) -> some View {
        content.navigationTitle(localizationManager.localizedString(for: titleKey))
    }
}

extension View {
    func localizedNavigationTitle(_ titleKey: String) -> some View {
        modifier(LocalizedNavigationTitle(titleKey))
    }
}