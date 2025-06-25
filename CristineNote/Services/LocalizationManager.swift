import Foundation
import SwiftUI

// 动态本地化管理器
@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "zh-Hans" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            UserDefaults.standard.synchronize()
            loadBundle()
        }
    }

    private var bundle: Bundle = Bundle.main

    private init() {
        // 从UserDefaults加载语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = savedLanguage
        } else {
            // 默认根据系统语言设置
            let systemLanguage: String?
            if #available(iOS 16, *) {
                systemLanguage = Locale.current.language.languageCode?.identifier
            } else {
                systemLanguage = Locale.current.languageCode
            }
            
            if let lang = systemLanguage {
                currentLanguage = lang == "zh" ? "zh-Hans" : "en"
            } else {
                currentLanguage = "zh-Hans"
            }
        }
        loadBundle()
    }

    private func loadBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }

        // 通知所有观察者语言已改变
        Task { @MainActor in
            self.objectWillChange.send()
        }
    }

    nonisolated func localizedString(for key: String, comment: String = "") -> String {
        // 使用 MainActor.assumeIsolated 来安全地访问 bundle 属性
        let currentBundle = MainActor.assumeIsolated { bundle }
        return NSLocalizedString(key, bundle: currentBundle, comment: comment)
    }

    func setLanguage(_ language: String) {
        currentLanguage = language
    }
}

// 便捷的本地化函数，替代NSLocalizedString
@MainActor
func LocalizedString(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

// 为非主角色上下文提供的异步版本
func LocalizedStringAsync(_ key: String, comment: String = "") async -> String {
    return await MainActor.run {
        return LocalizationManager.shared.localizedString(for: key, comment: comment)
    }
}

