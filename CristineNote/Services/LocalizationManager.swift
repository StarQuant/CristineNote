import Foundation
import SwiftUI

// 动态本地化管理器 - 重构避免Publishing错误
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "zh-Hans" {
        didSet {
            updateLanguage()
        }
    }

    private var bundle: Bundle = Bundle.main
    private let updateQueue = DispatchQueue(label: "LocalizationUpdate", qos: .userInitiated)

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

    private func updateLanguage() {
        updateQueue.async { [weak self] in
            UserDefaults.standard.set(self?.currentLanguage, forKey: "selectedLanguage")
            UserDefaults.standard.synchronize()
            
            DispatchQueue.main.async {
                self?.loadBundle()
            }
        }
    }

    private func loadBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }

        // 使用更安全的方式通知变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.objectWillChange.send()
        }
    }

    // 线程安全的本地化方法
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }

    func setLanguage(_ language: String) {
        DispatchQueue.main.async {
            self.currentLanguage = language
        }
    }
}

// 便捷的本地化函数 - 移除MainActor约束
func LocalizedString(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

// 为异步上下文提供的版本
func LocalizedStringAsync(_ key: String, comment: String = "") async -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

