import Foundation

// MARK: - API响应模型
struct ExchangeRateResponse: Codable {
    let base: String
    let rates: [String: Double]
    let date: String?
}

// MARK: - 汇率管理服务
@MainActor
class ExchangeRateService: ObservableObject {
    @Published var rates: [String: [String: Double]] = [:]
    @Published var lastUpdateTime: Date?
    @Published var isLoading = false
    
    private let ratesKey = "ExchangeRates"
    private let updateTimeKey = "RatesUpdateTime"
    
    // ExchangeRate-API配置（免费API，1500次/月）
    private let apiBaseURL = "https://api.exchangerate-api.com/v4/latest"
    
    init() {
        loadRates()
        setDefaultRatesIfNeeded()
    }
    
    // MARK: - 汇率转换
    func convert(amount: Double, from: Currency, to: Currency) -> Double {
        if from == to { return amount }
        
        // 获取汇率
        guard let fromRates = rates[from.apiCode],
              let rate = fromRates[to.apiCode] else {
            return amount // 如果没有汇率数据，返回原金额
        }
        
        return amount * rate
    }
    
    // MARK: - API获取汇率
    func fetchRatesFromAPI() async throws {
        isLoading = true
        
        do {
            var allRates: [String: [String: Double]] = [:]
            
            // 为每种货币获取汇率
            for baseCurrency in Currency.allCases {
                let rates = try await fetchRatesForBase(currency: baseCurrency)
                allRates[baseCurrency.apiCode] = rates
            }
            
            await MainActor.run {
                self.rates = allRates
                self.lastUpdateTime = Date()
                self.isLoading = false
                self.saveRates()
            }
            
            // 延迟触发UI更新，避免Publishing错误
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func fetchRatesForBase(currency: Currency) async throws -> [String: Double] {
        let urlString = "\(apiBaseURL)/\(currency.apiCode)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // 过滤出我们需要的货币
        let neededCurrencies = Currency.allCases.map { $0.apiCode }
        let filteredRates = response.rates.filter { neededCurrencies.contains($0.key) }
        
        return filteredRates
    }
    
    // MARK: - 手动设置汇率
    func setManualRate(from: Currency, to: Currency, rate: Double) async {
        await MainActor.run {
            if rates[from.apiCode] == nil {
                rates[from.apiCode] = [:]
            }
            rates[from.apiCode]?[to.apiCode] = rate
            
            // 计算反向汇率
            if rates[to.apiCode] == nil {
                rates[to.apiCode] = [:]
            }
            rates[to.apiCode]?[from.apiCode] = 1.0 / rate
            
            saveRates()
            
            // 延迟触发UI更新，避免Publishing错误
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - 获取汇率显示值
    func getRate(from: Currency, to: Currency) -> Double? {
        return rates[from.apiCode]?[to.apiCode]
    }
    
    // 获取特定汇率键的值（用于同步）
    func getRate(for key: String) -> Double {
        let components = key.split(separator: "_")
        if components.count == 2,
           let fromRates = rates[String(components[0])],
           let rate = fromRates[String(components[1])] {
            return rate
        }
        return 1.0
    }
    
    // 获取所有汇率（用于同步）
    func getAllRates() -> [String: Double] {
        var allRates: [String: Double] = [:]
        
        for (fromCurrency, toRates) in rates {
            for (toCurrency, rate) in toRates {
                let key = "\(fromCurrency)_\(toCurrency)"
                allRates[key] = rate
            }
        }
        
        return allRates
    }
    
    // MARK: - 设置默认汇率
    private func setDefaultRatesIfNeeded() {
        if rates.isEmpty {
            // 设置默认汇率（以CNY为基准）
            rates = [
                "CNY": ["CNY": 1.0, "PHP": 8.0, "USD": 0.14],
                "PHP": ["CNY": 0.125, "PHP": 1.0, "USD": 0.0175],
                "USD": ["CNY": 7.2, "PHP": 57.6, "USD": 1.0]
            ]
            saveRates()
        }
    }
    
    // MARK: - 数据持久化
    private func saveRates() {
        if let encoded = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(encoded, forKey: ratesKey)
        }
        if let updateTime = lastUpdateTime {
            UserDefaults.standard.set(updateTime, forKey: updateTimeKey)
        }
        UserDefaults.standard.synchronize()
    }
    
    private func loadRates() {
        if let data = UserDefaults.standard.data(forKey: ratesKey),
           let savedRates = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            rates = savedRates
        }
        lastUpdateTime = UserDefaults.standard.object(forKey: updateTimeKey) as? Date
    }
} 