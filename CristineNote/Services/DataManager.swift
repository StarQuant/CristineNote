import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var expenseCategories: [TransactionCategory] = []
    @Published var incomeCategories: [TransactionCategory] = []
    @Published var currentLanguage: String = "zh-Hans"
    
    private let transactionsKey = "SavedTransactions"
    private let expenseCategoriesKey = "ExpenseCategories"
    private let incomeCategoriesKey = "IncomeCategories"
    private let languageKey = "AppLanguage"
    

    
    init() {
        validateDataIntegrity()
        loadData()
    }
    
    // MARK: - 数据完整性检查
    private func validateDataIntegrity() {
        // 检查UserDefaults是否可访问
        do {
            let testKey = "DataIntegrityTest"
            UserDefaults.standard.set("test", forKey: testKey)
            UserDefaults.standard.synchronize()
            UserDefaults.standard.removeObject(forKey: testKey)
        } catch {
            print("⚠️ UserDefaults访问异常: \(error)")
        }
    }
    
    // MARK: - 数据加载和保存
    func loadData() {
        loadTransactions()
        loadCategories()
        loadLanguage()
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let savedTransactions = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = savedTransactions
        }
    }
    
    private func loadCategories() {
        // 加载支出分类
        if let data = UserDefaults.standard.data(forKey: expenseCategoriesKey),
           let savedCategories = try? JSONDecoder().decode([TransactionCategory].self, from: data) {
            expenseCategories = savedCategories
        } else {
            expenseCategories = createDefaultExpenseCategories()
            saveCategories()
        }
        
        // 加载收入分类
        if let data = UserDefaults.standard.data(forKey: incomeCategoriesKey),
           let savedCategories = try? JSONDecoder().decode([TransactionCategory].self, from: data) {
            incomeCategories = savedCategories
        } else {
            incomeCategories = createDefaultIncomeCategories()
            saveCategories()
        }
    }
    
    private func createDefaultExpenseCategories() -> [TransactionCategory] {
        var categories: [TransactionCategory] = []
        
        // 基础分类
        let basicCategories = [
            ("其他", "Others", "ellipsis.circle.fill", Color.gray),
            ("银行", "Bank", "building.columns.fill", Color.blue),
            ("SM购物", "Shopping", "bag.fill", Color.purple),
            ("买菜", "Grocery", "cart", Color.green),
        ]
        
        // 交通分类
        let transportCategories = [
            ("坐车", "Transportation", "bus.fill", Color.orange),
        ]
        
        // 生活费用分类
        let livingCategories = [
            ("房租", "Rent", "house.fill", Color.brown),
            ("水费", "Water Bill", "drop.fill", Color.blue),
            ("电费", "Electricity Bill", "lightbulb.fill", Color.yellow),
        ]
        
        // 汽车相关分类
        let carCategories = [
            ("汽车修理", "Car Repair", "wrench.and.screwdriver.fill", Color.red),
            ("汽车加油", "Gas", "fuelpump.fill", Color.orange),
        ]
        
        // 支付方式分类
        let paymentCategories = [
            ("网络支付", "Online Payment", "wifi", Color.cyan),
            ("线上支付", "Online Payment", "creditcard.fill", Color.indigo)
        ]
        
        // 合并所有分类
        let allCategoryData = basicCategories + transportCategories + livingCategories + carCategories + paymentCategories
        
        for (name, englishName, icon, color) in allCategoryData {
            categories.append(TransactionCategory(
                name: name,
                englishName: englishName,
                iconName: icon,
                color: color,
                type: .expense
            ))
        }
        
        return categories
    }
    
    private func createDefaultIncomeCategories() -> [TransactionCategory] {
        let incomeCategories = [
            ("其他", "Others", "ellipsis.circle.fill", Color.green)
        ]
        
        return incomeCategories.map { (name, englishName, icon, color) in
            TransactionCategory(
                name: name,
                englishName: englishName,
                iconName: icon,
                color: color,
                type: .income
            )
        }
    }
    
    func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
    
    func saveCategories() {
        if let expenseData = try? JSONEncoder().encode(expenseCategories) {
            UserDefaults.standard.set(expenseData, forKey: expenseCategoriesKey)
        }
        
        if let incomeData = try? JSONEncoder().encode(incomeCategories) {
            UserDefaults.standard.set(incomeData, forKey: incomeCategoriesKey)
        }
    }
    
    // MARK: - 交易操作
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
        }
    }
    
    // MARK: - 分类操作
    func addCategory(_ category: TransactionCategory) {
        switch category.type {
        case .expense:
            expenseCategories.append(category)
        case .income:
            incomeCategories.append(category)
        }
        saveCategories()
    }
    
    func deleteCategory(_ category: TransactionCategory) {
        switch category.type {
        case .expense:
            expenseCategories.removeAll { $0.id == category.id }
        case .income:
            incomeCategories.removeAll { $0.id == category.id }
        }
        saveCategories()
    }
    
    func updateCategory(_ category: TransactionCategory) {
        switch category.type {
        case .expense:
            if let index = expenseCategories.firstIndex(where: { $0.id == category.id }) {
                expenseCategories[index] = category
            }
        case .income:
            if let index = incomeCategories.firstIndex(where: { $0.id == category.id }) {
                incomeCategories[index] = category
            }
        }
        saveCategories()
    }
    
    // 更新使用已编辑分类的交易记录
    func updateTransactionsForEditedCategory(oldCategory: TransactionCategory, newCategory: TransactionCategory) {
        for index in transactions.indices {
            if transactions[index].category.id == oldCategory.id {
                transactions[index].category = newCategory
            }
        }
        saveTransactions()
    }
    
    // 为删除的分类创建"未分类"分类并更新相关交易
    func updateTransactionsForDeletedCategory(_ deletedCategory: TransactionCategory) {
        // 创建或获取"未分类"分类
        let uncategorizedCategory = getOrCreateUncategorizedCategory(for: deletedCategory.type)
        
        // 更新所有使用已删除分类的交易记录
        for index in transactions.indices {
            if transactions[index].category.id == deletedCategory.id {
                transactions[index].category = uncategorizedCategory
            }
        }
        saveTransactions()
    }
    
    private func getOrCreateUncategorizedCategory(for type: TransactionType) -> TransactionCategory {
        let uncategorizedName = LocalizedString("uncategorized")
        
        // 检查是否已存在未分类分类
        let categories = type == .expense ? expenseCategories : incomeCategories
        if let existing = categories.first(where: { $0.name == uncategorizedName }) {
            return existing
        }
        
        // 创建新的未分类分类
        let uncategorizedCategory = TransactionCategory(
            name: uncategorizedName,
            englishName: "Uncategorized",
            iconName: "questionmark.circle.fill",
            color: .gray,
            type: type
        )
        
        // 添加到相应的分类列表
        switch type {
        case .expense:
            expenseCategories.append(uncategorizedCategory)
        case .income:
            incomeCategories.append(uncategorizedCategory)
        }
        saveCategories()
        
        return uncategorizedCategory
    }
    
    // MARK: - 统计数据
    func getTotalIncome(for period: StatisticsPeriod = .thisMonth, customStartDate: Date? = nil, customEndDate: Date? = nil) -> Double {
        let filteredTransactions = getTransactions(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
        return filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getTotalExpense(for period: StatisticsPeriod = .thisMonth, customStartDate: Date? = nil, customEndDate: Date? = nil) -> Double {
        let filteredTransactions = getTransactions(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
        return filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getBalance(for period: StatisticsPeriod = .thisMonth, customStartDate: Date? = nil, customEndDate: Date? = nil) -> Double {
        return getTotalIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate) - getTotalExpense(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
    }
    
    func getTransactions(for period: StatisticsPeriod, customStartDate: Date? = nil, customEndDate: Date? = nil) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            let startDate = calendar.startOfDay(for: now)
            return transactions.filter { $0.date >= startDate }
        case .thisWeek:
            let startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return transactions.filter { $0.date >= startDate }
        case .thisMonth:
            let startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return transactions.filter { $0.date >= startDate }
        case .custom:
            guard let startDate = customStartDate, let endDate = customEndDate else {
                return transactions
            }
            let endOfDay = calendar.startOfDay(for: endDate.addingTimeInterval(24 * 60 * 60))
            return transactions.filter { $0.date >= startDate && $0.date < endOfDay }
        case .all:
            return transactions
        }
    }
    
    func getCategoryExpenses(for period: StatisticsPeriod = .thisMonth, customStartDate: Date? = nil, customEndDate: Date? = nil) -> [(category: TransactionCategory, amount: Double)] {
        let filteredTransactions = getTransactions(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            .filter { $0.type == .expense }
        
        var categoryAmounts: [String: (category: TransactionCategory, amount: Double)] = [:]
        
        for transaction in filteredTransactions {
            let key = transaction.category.id.uuidString
            if let existing = categoryAmounts[key] {
                categoryAmounts[key] = (existing.category, existing.amount + transaction.amount)
            } else {
                categoryAmounts[key] = (transaction.category, transaction.amount)
            }
        }
        
        return Array(categoryAmounts.values).sorted { $0.amount > $1.amount }
    }
    
    func getCategoryIncome(for period: StatisticsPeriod = .thisMonth, customStartDate: Date? = nil, customEndDate: Date? = nil) -> [(category: TransactionCategory, amount: Double)] {
        let filteredTransactions = getTransactions(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            .filter { $0.type == .income }
        
        var categoryAmounts: [String: (category: TransactionCategory, amount: Double)] = [:]
        
        for transaction in filteredTransactions {
            let key = transaction.category.id.uuidString
            if let existing = categoryAmounts[key] {
                categoryAmounts[key] = (existing.category, existing.amount + transaction.amount)
            } else {
                categoryAmounts[key] = (transaction.category, transaction.amount)
            }
        }
        
        return Array(categoryAmounts.values).sorted { $0.amount > $1.amount }
    }
    
    // MARK: - 语言设置
    @MainActor private func loadLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey) {
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
            saveLanguage()
        }
        
        // 同步到LocalizationManager
        LocalizationManager.shared.setLanguage(currentLanguage)
    }
    
    @MainActor func setLanguage(_ language: String) {
        currentLanguage = language
        saveLanguage()
        
        // 同步到LocalizationManager
        LocalizationManager.shared.setLanguage(language)
    }
    
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage, forKey: languageKey)
        UserDefaults.standard.synchronize()
    }
    

    
    // MARK: - 数据清理和重置
    

    
    /// 重置所有分类数据到默认状态
    func resetCategoriesToDefault() {
        print("🔄 重置分类数据到默认状态")
        
        // 清除保存的分类数据
        UserDefaults.standard.removeObject(forKey: expenseCategoriesKey)
        UserDefaults.standard.removeObject(forKey: incomeCategoriesKey)
        
        // 重新创建默认分类
        expenseCategories = createDefaultExpenseCategories()
        incomeCategories = createDefaultIncomeCategories()
        
        // 保存新的默认分类
        saveCategories()
        
        print("✅ 分类数据重置完成")
    }
    

}

// MARK: - 统计周期
enum StatisticsPeriod: String, CaseIterable {
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case custom = "custom"
    case all = "all_time"
    
    var localizedName: String {
        if Thread.isMainThread {
            return LocalizationManager.shared.localizedString(for: self.rawValue)
        } else {
            return DispatchQueue.main.sync {
                return LocalizationManager.shared.localizedString(for: self.rawValue)
            }
        }
    }
} 