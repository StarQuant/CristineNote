import Foundation
import SwiftUI

// MARK: - 货币类型
enum Currency: String, CaseIterable, Codable {
    case php = "PHP"  // 菲律宾比索（默认）
    case cny = "CNY"  // 人民币
    case usd = "USD"  // 美元
    
    var symbol: String {
        switch self {
        case .php:
            return "₱"
        case .cny:
            return "¥"
        case .usd:
            return "$"
        }
    }
    
    @MainActor var displayName: String {
        switch self {
        case .php:
            return LocalizationManager.shared.localizedString(for: "currency_php")
        case .cny:
            return LocalizationManager.shared.localizedString(for: "currency_cny")
        case .usd:
            return LocalizationManager.shared.localizedString(for: "currency_usd")
        }
    }
    
    var apiCode: String {
        return self.rawValue
    }
    
    static var defaultCurrency: Currency {
        return .php
    }
    
    // 从API代码获取货币
    static func fromAPICode(_ code: String) -> Currency? {
        switch code.uppercased() {
        case "PHP": return .php
        case "CNY": return .cny
        case "USD": return .usd
        default: return nil
        }
    }
} 