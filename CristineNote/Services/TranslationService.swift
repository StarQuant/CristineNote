import Foundation

@MainActor
class TranslationService: ObservableObject {
    @Published var isTranslating = false


    private let baseURL = "https://api.openai.com/v1/chat/completions"

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OpenAI_API_Key")
    }

    func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }

    var hasValidAPIKey: Bool {
        guard let key = getAPIKey() else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func translateText(_ text: String, from sourceLanguage: String = "en", to targetLanguage: String = "zh-CN") async throws -> String {
        // 首先尝试OpenAI翻译
        if let apiKey = getAPIKey(), !apiKey.isEmpty {
            return try await translateWithOpenAI(text, from: sourceLanguage, to: targetLanguage)
        } else {
            // 没有API密钥时使用iOS系统翻译
            return try await translateWithiOS(text, from: sourceLanguage, to: targetLanguage)
        }
    }

    func translateToEnglish(_ text: String) async throws -> String {
        // 首先尝试OpenAI翻译
        if let apiKey = getAPIKey(), !apiKey.isEmpty {
            return try await translateToEnglishWithOpenAI(text)
        } else {
            // 没有API密钥时使用iOS系统翻译
            return try await translateWithiOS(text, from: "zh-CN", to: "en")
        }
    }

    // MARK: - OpenAI翻译方法
    private func translateWithOpenAI(_ text: String, from sourceLanguage: String = "en", to targetLanguage: String = "zh-CN") async throws -> String {

        guard !text.isEmpty else {
            throw TranslationError.emptyText
        }

        await MainActor.run {
            self.isTranslating = true
        }

        defer {
            Task { @MainActor in
                self.isTranslating = false
            }
        }

        let prompt = "请将以下文本翻译成中文，只返回翻译结果，不要添加任何解释：\(text)"

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 100,
            "temperature": 0.3
        ]

        guard let url = URL(string: baseURL) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAPIKey() ?? "")", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TranslationError.encodingError
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TranslationError.apiError(httpResponse.statusCode)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw TranslationError.parseError
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkError(error)
        }
    }

    private func translateToEnglishWithOpenAI(_ text: String) async throws -> String {

        guard !text.isEmpty else {
            throw TranslationError.emptyText
        }

        await MainActor.run {
            self.isTranslating = true
        }

        defer {
            Task { @MainActor in
                self.isTranslating = false
            }
        }

        let prompt = "请将以下中文词汇翻译成对应的英文单词或短语，只返回英文翻译结果，不要添加任何解释或标点符号：\(text)"

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 50,
            "temperature": 0.1
        ]

        guard let url = URL(string: baseURL) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAPIKey() ?? "")", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TranslationError.encodingError
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TranslationError.apiError(httpResponse.statusCode)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw TranslationError.parseError
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkError(error)
        }
    }

    func detectLanguage(_ text: String) -> Bool {
        // 简单的语言检测：如果包含中文字符则认为是中文，否则认为是英文
        let chineseRange = text.range(of: "\\p{Han}", options: .regularExpression)
        return chineseRange == nil // 如果没有中文字符，返回true（需要翻译）
    }

    // MARK: - iOS系统翻译方法
    private func translateWithiOS(_ text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        guard !text.isEmpty else {
            throw TranslationError.emptyText
        }

        await MainActor.run {
            self.isTranslating = true
        }

        defer {
            Task { @MainActor in
                self.isTranslating = false
            }
        }

        // 使用基础词典翻译作为备选方案
        return try translateWithBasicDictionary(text, from: sourceLanguage, to: targetLanguage)
    }

    // 基础词典翻译（作为最后的fallback）
    private func translateWithBasicDictionary(_ text: String, from sourceLanguage: String, to targetLanguage: String) throws -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 扩展的基础中英文词典
        let chineseToEnglish: [String: String] = [
            // 默认分类
            "其他": "Others",
            "银行": "Bank",
            "SM购物": "Shopping",
            "购物": "Shopping",
            "买菜": "Grocery",
            "坐车": "Transportation",
            "房租": "Rent",
            "水费": "Water Bill",
            "电费": "Electricity Bill",
            "汽车修理": "Car Repair",
            "汽车加油": "Gas",
            "网络支付": "Online Payment",

            // 常用分类扩展
            "餐饮": "Dining",
            "交通": "Transportation",
            "娱乐": "Entertainment",
            "医疗": "Medical",
            "教育": "Education",
            "通讯": "Communication",
            "服装": "Clothing",
            "美容": "Beauty",
            "健身": "Fitness",
            "旅游": "Travel",
            "礼品": "Gifts",
            "保险": "Insurance",
            "维修": "Maintenance",
            "宠物": "Pet",
            "家具": "Furniture",
            "电器": "Appliances",

            // 收入分类
            "工资": "Salary",
            "奖金": "Bonus",
            "投资": "Investment",
            "兼职": "Part-time",
            "理财": "Financial Management",
            "股票": "Stocks",
            "基金": "Funds",
            "外快": "Side Income",

            // 常用词汇
            "早餐": "Breakfast",
            "午餐": "Lunch",
            "晚餐": "Dinner",
            "咖啡": "Coffee",
            "超市": "Supermarket",
            "出租车": "Taxi",
            "地铁": "Subway",
            "公交": "Bus",
            "停车": "Parking",
            "电影": "Movie",
            "书籍": "Books",
            "药品": "Medicine",
            "话费": "Phone Bill",
            "网费": "Internet Bill",
            "煤气": "Gas Bill"
        ]

        let englishToChinese: [String: String] = [
            // 基础分类
            "others": "其他",
            "bank": "银行",
            "shopping": "购物",
            "grocery": "买菜",
            "transportation": "交通",
            "rent": "房租",
            "water bill": "水费",
            "electricity bill": "电费",
            "car repair": "汽车修理",
            "gas": "汽车加油",
            "online payment": "网络支付",

            // 扩展分类
            "dining": "餐饮",
            "entertainment": "娱乐",
            "medical": "医疗",
            "education": "教育",
            "communication": "通讯",
            "clothing": "服装",
            "beauty": "美容",
            "fitness": "健身",
            "travel": "旅游",
            "gifts": "礼品",
            "insurance": "保险",
            "maintenance": "维修",
            "pet": "宠物",
            "furniture": "家具",
            "appliances": "电器",

            // 收入分类
            "salary": "工资",
            "bonus": "奖金",
            "investment": "投资",
            "part-time": "兼职",
            "financial management": "理财",
            "stocks": "股票",
            "funds": "基金",
            "side income": "外快",

            // 常用词汇
            "breakfast": "早餐",
            "lunch": "午餐",
            "dinner": "晚餐",
            "coffee": "咖啡",
            "supermarket": "超市",
            "taxi": "出租车",
            "subway": "地铁",
            "bus": "公交",
            "parking": "停车",
            "movie": "电影",
            "books": "书籍",
            "medicine": "药品",
            "phone bill": "话费",
            "internet bill": "网费",
            "gas bill": "煤气"
        ]

        if sourceLanguage == "zh-CN" && targetLanguage == "en" {
            return chineseToEnglish[text] ?? text
        } else if sourceLanguage == "en" && targetLanguage == "zh-CN" {
            return englishToChinese[trimmedText] ?? text
        }

        return text // 如果找不到翻译，返回原文
    }
}

enum TranslationError: LocalizedError {
    case noAPIKey           // 仅用于提示，不再阻止翻译
    case emptyText
    case invalidURL
    case encodingError
    case invalidResponse
    case apiError(Int)
    case parseError
    case networkError(Error)
    case systemTranslationUnavailable

    var errorDescription: String? {
        // 使用nonisolated方式访问本地化字符串
        return MainActor.assumeIsolated {
            switch self {
            case .noAPIKey:
                return LocalizedString("translation_error_no_api_key")
            case .emptyText:
                return LocalizedString("translation_error_empty_text")
            case .invalidURL:
                return LocalizedString("translation_error_invalid_url")
            case .encodingError:
                return LocalizedString("translation_error_encoding")
            case .invalidResponse:
                return LocalizedString("translation_error_invalid_response")
            case .apiError(let code):
                return String(format: LocalizedString("translation_error_api"), code)
            case .parseError:
                return LocalizedString("translation_error_parsing")
            case .networkError(let error):
                return String(format: LocalizedString("translation_error_network"), error.localizedDescription)
            case .systemTranslationUnavailable:
                return LocalizedString("translation_error_system_unavailable")
            }
        }
    }
}