import Foundation
import SwiftUI

// MARK: - 同步数据包装结构
struct SyncDataPackage: Codable {
    let deviceInfo: DeviceInfo
    let transactions: [Transaction]
    let expenseCategories: [TransactionCategory]
    let incomeCategories: [TransactionCategory]
    let systemCurrency: Currency
    let exchangeRates: [String: Double]
    let timestamp: Date
    let packageId: UUID
    
    init(deviceInfo: DeviceInfo, transactions: [Transaction], expenseCategories: [TransactionCategory], incomeCategories: [TransactionCategory], systemCurrency: Currency, exchangeRates: [String: Double]) {
        self.deviceInfo = deviceInfo
        self.transactions = transactions
        self.expenseCategories = expenseCategories
        self.incomeCategories = incomeCategories
        self.systemCurrency = systemCurrency
        self.exchangeRates = exchangeRates
        self.timestamp = Date()
        self.packageId = UUID()
    }
}

// MARK: - 设备信息
struct DeviceInfo: Codable {
    let deviceName: String
    let deviceId: UUID
    let appVersion: String
    let lastSyncTime: Date?
    
    init() {
        self.deviceName = UIDevice.current.name
        self.deviceId = Self.getDeviceId()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.lastSyncTime = UserDefaults.standard.object(forKey: "LastSyncTime") as? Date
    }
    
    private static func getDeviceId() -> UUID {
        let key = "DeviceUUID"
        if let uuidString = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        } else {
            let newUUID = UUID()
            UserDefaults.standard.set(newUUID.uuidString, forKey: key)
            return newUUID
        }
    }
}

// MARK: - 同步状态
enum SyncState: Equatable {
    case idle
    case advertising
    case browsing
    case connecting
    case connected
    case syncing
    case completed
    case failed(Error)
    
    var displayName: String {
        // 需要在主线程执行以避免并发问题
        if Thread.isMainThread {
            return getLocalizedDisplayName()
        } else {
            return DispatchQueue.main.sync {
                return getLocalizedDisplayName()
            }
        }
    }
    
    private func getLocalizedDisplayName() -> String {
        switch self {
        case .idle:
            return LocalizationManager.shared.localizedString(for: "idle")
        case .advertising:
            return LocalizationManager.shared.localizedString(for: "advertising")
        case .browsing:
            return LocalizationManager.shared.localizedString(for: "browsing")
        case .connecting:
            return LocalizationManager.shared.localizedString(for: "connecting")
        case .connected:
            return LocalizationManager.shared.localizedString(for: "connected")
        case .syncing:
            return LocalizationManager.shared.localizedString(for: "syncing")
        case .completed:
            return LocalizationManager.shared.localizedString(for: "sync_completed")
        case .failed:
            return LocalizationManager.shared.localizedString(for: "sync_failed")
        }
    }
    
    // 手动实现Equatable协议
    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.advertising, .advertising),
             (.browsing, .browsing),
             (.connecting, .connecting),
             (.connected, .connected),
             (.syncing, .syncing),
             (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - 同步结果
struct SyncResult: Codable {
    let isSuccess: Bool
    let transactionsAdded: Int
    let transactionsDuplicated: Int
    let categoriesAdded: Int
    let categoriesDuplicated: Int
    let exchangeRatesSynced: Int
    let currencySettingsSynced: Bool
    let errorMessage: String?
    
    static let empty = SyncResult(
        isSuccess: true,
        transactionsAdded: 0,
        transactionsDuplicated: 0,
        categoriesAdded: 0,
        categoriesDuplicated: 0,
        exchangeRatesSynced: 0,
        currencySettingsSynced: false,
        errorMessage: nil
    )
}

// MARK: - 同步模式
enum SyncMode: Equatable {
    case generate  // 生成二维码等待连接
    case scan      // 扫描二维码主动连接
}

// MARK: - 消息类型
enum SyncMessageType: String, Codable {
    case deviceInfo = "device_info"
    case syncStart = "sync_start"        // 新增：通知对方开始同步
    case dataRequest = "data_request"
    case dataResponse = "data_response"
    case syncComplete = "sync_complete"
    case error = "error"
}

// MARK: - 同步消息
struct SyncMessage: Codable {
    let type: SyncMessageType
    let payload: Data
    let timestamp: Date
    let messageId: UUID
    
    init(type: SyncMessageType, payload: Data) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
        self.messageId = UUID()
    }
}

// MARK: - 重复检测配置
struct DuplicateDetectionConfig {
    static let timeToleranceInSeconds: TimeInterval = 120 // 2分钟容差
    static let enableSmartMerging = true
    static let conflictResolutionStrategy: ConflictResolutionStrategy = .keepNewer
}

// MARK: - 冲突解决策略
enum ConflictResolutionStrategy: Equatable {
    case keepNewer      // 保留较新的记录
    case keepOlder      // 保留较旧的记录
    case askUser        // 询问用户
    case merge          // 智能合并
} 