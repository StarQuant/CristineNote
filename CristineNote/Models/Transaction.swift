import Foundation
import SwiftUI
import UIKit

// MARK: - 交易类型
enum TransactionType: String, CaseIterable, Codable {
    case income = "income"
    case expense = "expense"

    @MainActor var displayName: String {
        switch self {
        case .income:
            return LocalizationManager.shared.localizedString(for: "income")
        case .expense:
            return LocalizationManager.shared.localizedString(for: "expense")
        }
    }

    var color: Color {
        switch self {
        case .income:
            return .green
        case .expense:
            return .red
        }
    }

    var iconName: String {
        switch self {
        case .income:
            return "plus.circle"
        case .expense:
            return "minus.circle"
        }
    }
}

// MARK: - 交易分类
struct TransactionCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var englishName: String?
    var iconName: String
    var color: Color
    var type: TransactionType

    // 根据当前语言动态显示分类名称
    @MainActor func displayName(for dataManager: DataManager) -> String {
        if dataManager.currentLanguage == "zh-Hans" {
            return name
        } else {
            return englishName ?? name
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, englishName, iconName, type
        case colorData = "color"
    }

    init(id: UUID = UUID(), name: String, englishName: String? = nil, iconName: String, color: Color, type: TransactionType) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.iconName = iconName
        self.color = color
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 处理id字段的向后兼容性
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID() // 为旧数据生成新ID
        }

        name = try container.decode(String.self, forKey: .name)
        englishName = try? container.decode(String.self, forKey: .englishName)
        iconName = try container.decode(String.self, forKey: .iconName)
        type = try container.decode(TransactionType.self, forKey: .type)

        if let colorData = try? container.decode(Data.self, forKey: .colorData),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            color = Color(uiColor)
        } else {
            color = .blue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(englishName, forKey: .englishName)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(type, forKey: .type)

        let uiColor = UIColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            try container.encode(colorData, forKey: .colorData)
        }
    }


}

// MARK: - 交易记录
struct Transaction: Identifiable, Codable {
    let id: UUID
    let originalAmount: Double      // 原始录入金额
    let originalCurrency: Currency  // 原始录入币种
    let type: TransactionType
    var category: TransactionCategory
    let note: String
    let date: Date
    var originalNote: String? // 用于存储翻译前的原文

    init(amount: Double, currency: Currency = Currency.defaultCurrency, type: TransactionType, category: TransactionCategory, note: String = "", date: Date = Date()) {
        self.id = UUID()
        self.originalAmount = amount
        self.originalCurrency = currency
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.originalNote = nil
    }
    
    // 为了向后兼容旧数据
    enum CodingKeys: String, CodingKey {
        case id, originalAmount, originalCurrency, type, category, note, date, originalNote
        case amount // 兼容旧字段
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(TransactionType.self, forKey: .type)
        category = try container.decode(TransactionCategory.self, forKey: .category)
        note = try container.decode(String.self, forKey: .note)
        date = try container.decode(Date.self, forKey: .date)
        originalNote = try? container.decode(String.self, forKey: .originalNote)
        
        // 处理新旧字段兼容
        if let newAmount = try? container.decode(Double.self, forKey: .originalAmount) {
            originalAmount = newAmount
            originalCurrency = try container.decodeIfPresent(Currency.self, forKey: .originalCurrency) ?? .cny
        } else {
            // 兼容旧数据
            originalAmount = try container.decode(Double.self, forKey: .amount)
            originalCurrency = .cny // 旧数据默认为人民币
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originalAmount, forKey: .originalAmount)
        try container.encode(originalCurrency, forKey: .originalCurrency)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(note, forKey: .note)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(originalNote, forKey: .originalNote)
    }

    // 格式化显示金额（在指定货币下）
    @MainActor func formattedAmount(in targetCurrency: Currency, exchangeRateService: ExchangeRateService) -> String {
        let convertedAmount = exchangeRateService.convert(
            amount: originalAmount,
            from: originalCurrency,
            to: targetCurrency
        )
        return formatCurrency(convertedAmount, currency: targetCurrency)
    }
    
    // 显示原始金额信息
    var originalAmountText: String {
        return formatCurrency(originalAmount, currency: originalCurrency)
    }

    var displayAmount: String {
        let prefix = type == .income ? "+" : "-"
        return prefix + originalAmountText
    }
}

// MARK: - 货币格式化工具函数
func formatCurrency(_ amount: Double, currency: Currency) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency.apiCode
    formatter.currencySymbol = currency.symbol
    formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
    return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)0"
}

// MARK: - Color Codable Support
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)

        guard let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid color data"
            )
        }

        self = Color(color)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false)
        try container.encode(data)
    }
}