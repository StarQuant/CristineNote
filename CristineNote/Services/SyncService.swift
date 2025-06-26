import Foundation
import SwiftUI
import MultipeerConnectivity

@MainActor
class SyncService: ObservableObject {
    private let networkManager: SyncNetworkManager
    private let dataManager: DataManager
    
    @Published var syncResult: SyncResult = .empty
    @Published var isShowingProgress = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatus: String = ""
    @Published var syncState: SyncState = .idle
    
    private var currentDeviceInfo: DeviceInfo
    private var lastOperation: SyncOperation?
    
    enum SyncOperation {
        case generateMode
        case scanMode
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.networkManager = SyncNetworkManager()
        self.currentDeviceInfo = DeviceInfo()
        self.syncState = networkManager.syncState
        
        setupNetworkCallbacks()
    }
    
    // MARK: - 公共方法
    
    /// 开始生成模式同步（显示二维码等待连接）
    func startGenerateMode() {
        lastOperation = .generateMode
        currentDeviceInfo = DeviceInfo()
        networkManager.startAdvertising(with: currentDeviceInfo)
    }
    
    /// 开始扫描模式同步（搜索并连接设备）
    func startScanMode() {
        lastOperation = .scanMode
        currentDeviceInfo = DeviceInfo()
        networkManager.startBrowsing()
    }
    
    /// 重试最后一次操作
    func retryLastOperation() {
        // 如果是网络管理器层面的错误，直接重试网络操作
        if case .failed = networkManager.syncState {
            networkManager.retryLastOperation()
            return
        }
        
        guard let operation = lastOperation else { return }
        
        // 先停止当前服务
        stopSync()
        
        // 等待一秒后重试
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch operation {
            case .generateMode:
                self.startGenerateMode()
            case .scanMode:
                self.startScanMode()
            }
        }
    }
    
    /// 重置状态
    func reset() {
        stopSync()
        lastOperation = nil
        syncResult = .empty
    }
    
    /// 完全重置（解决组件重用问题）
    func resetCompletely() {
        // 重置本地状态
        stopSync()
        lastOperation = nil
        syncResult = .empty
        
        // 重置网络管理器
        networkManager.resetCompletely()
    }
    
    /// 停止同步
    func stopSync() {
        networkManager.stopAll()
        isShowingProgress = false
        syncProgress = 0.0
        syncStatus = ""
    }
    
    /// 获取连接的设备
    var connectedPeers: [MCPeerID] {
        networkManager.connectedPeers
    }
    
    // MARK: - 私有方法
    
    private func setupNetworkCallbacks() {
        // 设置数据接收回调
        networkManager.onDataReceived = { [weak self] data, peer in
            Task { @MainActor in
                await self?.handleReceivedData(data, from: peer)
            }
        }
        
        // 设置连接状态变化回调
        networkManager.onConnectionStateChanged = { [weak self] state, peer in
            Task { @MainActor in
                self?.handleConnectionStateChange(state, peer: peer)
            }
        }
        
        // 设置同步状态变化监听
        networkManager.onSyncStateChanged = { [weak self] newState in
            Task { @MainActor in
                self?.syncState = newState
            }
        }
    }
    
    private func handleConnectionStateChange(_ state: MCSessionState, peer: MCPeerID) {
        switch state {
        case .connected:
            // 连接成功后开始同步
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_connected_start")
            Task {
                await startDataSync()
            }
        case .notConnected:
            if isShowingProgress {
                syncStatus = LocalizationManager.shared.localizedString(for: "sync_connection_lost")
                isShowingProgress = false
            }
        default:
            break
        }
    }
    
    private func handleReceivedData(_ data: Data, from peer: MCPeerID) async {
        do {
            let message = try JSONDecoder().decode(SyncMessage.self, from: data)
            
            switch message.type {
            case .deviceInfo:
                await handleDeviceInfo(message.payload, from: peer)
            case .dataRequest:
                await handleDataRequest(from: peer)
            case .dataResponse:
                await handleDataResponse(message.payload, from: peer)
            case .syncComplete:
                await handleSyncComplete(message.payload)
            case .error:
                handleSyncError(message.payload)
            }
        } catch {
            // 解析消息失败，忽略这条消息
        }
    }
    
    private func startDataSync() async {
        isShowingProgress = true
        syncProgress = 0.1
        syncStatus = LocalizationManager.shared.localizedString(for: "sync_preparing")
        
        do {
            // 1. 发送设备信息
            let deviceInfoData = try JSONEncoder().encode(currentDeviceInfo)
            try networkManager.sendSyncMessage(type: .deviceInfo, payload: deviceInfoData)
            
            syncProgress = 0.3
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_sending_device_info")
            
            // 2. 请求对方数据
            let requestData = Data()
            try networkManager.sendSyncMessage(type: .dataRequest, payload: requestData)
            
            syncProgress = 0.5
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_waiting_data")
            
        } catch {
            syncResult = SyncResult(
                isSuccess: false,
                transactionsAdded: 0,
                transactionsDuplicated: 0,
                categoriesAdded: 0,
                categoriesDuplicated: 0,
                exchangeRatesSynced: 0,
                currencySettingsSynced: false,
                errorMessage: error.localizedDescription
            )
            isShowingProgress = false
        }
    }
    
    private func handleDeviceInfo(_ data: Data, from peer: MCPeerID) async {
        do {
            let deviceInfo = try JSONDecoder().decode(DeviceInfo.self, from: data)
            syncStatus = "\(LocalizationManager.shared.localizedString(for: "sync_received_device_info")): \(deviceInfo.deviceName)"
        } catch {
            // 解析设备信息失败
        }
    }
    
    private func handleDataRequest(from peer: MCPeerID) async {
        do {
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_sending_local_data")
            
            // 创建同步数据包
            let syncPackage = SyncDataPackage(
                deviceInfo: currentDeviceInfo,
                transactions: dataManager.transactions,
                expenseCategories: dataManager.expenseCategories,
                incomeCategories: dataManager.incomeCategories,
                systemCurrency: dataManager.currentSystemCurrency,
                exchangeRates: dataManager.exchangeRateService.getAllRates()
            )
            
            let packageData = try JSONEncoder().encode(syncPackage)
            try networkManager.sendSyncMessage(type: .dataResponse, payload: packageData)
            
            
        } catch {
            // 发送数据失败
        }
    }
    
    private func handleDataResponse(_ data: Data, from peer: MCPeerID) async {
        do {
            syncProgress = 0.7
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_processing_data")
            
            let syncPackage = try JSONDecoder().decode(SyncDataPackage.self, from: data)
            
            // 执行数据同步
            let result = await performDataSync(with: syncPackage)
            
            syncProgress = 0.9
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_merging_data")
            
            // 发送同步完成消息
            let resultData = try JSONEncoder().encode(result)
            try networkManager.sendSyncMessage(type: .syncComplete, payload: resultData)
            
            // 更新最后同步时间
            UserDefaults.standard.set(Date(), forKey: "LastSyncTime")
            
            syncResult = result
            syncProgress = 1.0
            syncStatus = LocalizationManager.shared.localizedString(for: "sync_completed")
            
            // 延迟关闭进度显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isShowingProgress = false
            }
            
        } catch {
            handleSyncError(Data())
        }
    }
    
    private func handleSyncComplete(_ data: Data) async {
        syncProgress = 1.0
        syncStatus = LocalizationManager.shared.localizedString(for: "sync_completed")
        
        // 延迟关闭进度显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isShowingProgress = false
        }
    }
    
    private func handleSyncError(_ data: Data) {
        syncResult = SyncResult(
            isSuccess: false,
            transactionsAdded: 0,
            transactionsDuplicated: 0,
            categoriesAdded: 0,
            categoriesDuplicated: 0,
            exchangeRatesSynced: 0,
            currencySettingsSynced: false,
            errorMessage: LocalizationManager.shared.localizedString(for: "sync_error_occurred")
        )
        isShowingProgress = false
    }
    
    // MARK: - 数据同步核心逻辑
    
    private func performDataSync(with syncPackage: SyncDataPackage) async -> SyncResult {
        var transactionsAdded = 0
        var transactionsDuplicated = 0
        var categoriesAdded = 0
        var categoriesDuplicated = 0
        var exchangeRatesSynced = 0
        var currencySettingsSynced = false
        
        // 1. 同步货币设置（可选，询问用户是否同步系统货币）
        currencySettingsSynced = await syncCurrencySettings(from: syncPackage)
        
        // 2. 同步汇率数据
        exchangeRatesSynced = syncExchangeRates(from: syncPackage)
        
        // 3. 同步分类数据
        for category in syncPackage.expenseCategories + syncPackage.incomeCategories {
            if !isDuplicateCategory(category) {
                dataManager.addCategory(category)
                categoriesAdded += 1
            } else {
                categoriesDuplicated += 1
            }
        }
        
        // 4. 同步交易数据
        for transaction in syncPackage.transactions {
            if !isDuplicateTransaction(transaction) {
                // 确保分类存在，如果不存在则创建或使用默认分类
                let validTransaction = ensureValidCategory(for: transaction)
                dataManager.addTransaction(validTransaction)
                transactionsAdded += 1
            } else {
                transactionsDuplicated += 1
            }
        }
        
        return SyncResult(
            isSuccess: true,
            transactionsAdded: transactionsAdded,
            transactionsDuplicated: transactionsDuplicated,
            categoriesAdded: categoriesAdded,
            categoriesDuplicated: categoriesDuplicated,
            exchangeRatesSynced: exchangeRatesSynced,
            currencySettingsSynced: currencySettingsSynced,
            errorMessage: nil
        )
    }
    
    // MARK: - 货币和汇率同步
    
    private func syncCurrencySettings(from syncPackage: SyncDataPackage) async -> Bool {
        // 只有当对方的系统货币与本地不同时才考虑同步
        if syncPackage.systemCurrency != dataManager.currentSystemCurrency {
            // 这里可以添加用户选择逻辑，现在默认保持本地设置
            // 未来可以显示提示让用户选择是否同步货币设置
            // return true 表示用户选择同步了货币设置
            return false
        }
        return false
    }
    
    private func syncExchangeRates(from syncPackage: SyncDataPackage) -> Int {
        var syncedCount = 0
        
        // 合并汇率数据，保留最新的汇率信息
        for (rateKey, rateValue) in syncPackage.exchangeRates {
            let currentRate = dataManager.exchangeRateService.getRate(for: rateKey)
            
            // 如果本地没有这个汇率或者对方的汇率更新，则使用对方的汇率
            if currentRate == 1.0 || rateValue != 1.0 {
                // 解析汇率键
                let components = rateKey.split(separator: "_")
                if components.count == 2 {
                    let fromCurrency = String(components[0])
                    let toCurrency = String(components[1])
                    
                    if let from = Currency.fromAPICode(fromCurrency),
                       let to = Currency.fromAPICode(toCurrency) {
                        dataManager.exchangeRateService.setManualRate(from: from, to: to, rate: rateValue)
                        syncedCount += 1
                    }
                }
            }
        }
        
        return syncedCount
    }
    
    // MARK: - 重复检测逻辑（增强版）
    
    private func isDuplicateTransaction(_ transaction: Transaction) -> Bool {
        return dataManager.transactions.contains { existing in
            // 1. UUID完全匹配
            if existing.id == transaction.id {
                return true
            }
            
            // 2. 基于时间、金额、分类和备注的智能检测
            let timeDiff = abs(existing.date.timeIntervalSince(transaction.date))
            
            return timeDiff < DuplicateDetectionConfig.timeToleranceInSeconds &&
                   existing.originalAmount == transaction.originalAmount &&
                   existing.originalCurrency == transaction.originalCurrency &&
                   existing.type == transaction.type &&
                   existing.category.id == transaction.category.id &&
                   existing.note == transaction.note
        }
    }
    
    private func isDuplicateCategory(_ category: TransactionCategory) -> Bool {
        let existingCategories = category.type == .expense ? 
            dataManager.expenseCategories : dataManager.incomeCategories
        
        return existingCategories.contains { existing in
            // 1. UUID完全匹配
            if existing.id == category.id {
                return true
            }
            
            // 2. 名称和类型匹配
            return existing.name == category.name && existing.type == category.type
        }
    }
    
    private func ensureValidCategory(for transaction: Transaction) -> Transaction {
        let existingCategories = transaction.type == .expense ? 
            dataManager.expenseCategories : dataManager.incomeCategories
        
        // 检查分类是否存在
        if existingCategories.contains(where: { $0.id == transaction.category.id }) {
            return transaction
        }
        
        // 尝试按名称匹配
        if let matchingCategory = existingCategories.first(where: { $0.name == transaction.category.name }) {
            var updatedTransaction = transaction
            updatedTransaction.category = matchingCategory
            return updatedTransaction
        }
        
        // 使用默认分类
        let defaultCategory = existingCategories.first ?? createDefaultCategory(for: transaction.type)
        var updatedTransaction = transaction
        updatedTransaction.category = defaultCategory
        return updatedTransaction
    }
    
    private func createDefaultCategory(for type: TransactionType) -> TransactionCategory {
        let defaultCategory = TransactionCategory(
                            name: LocalizationManager.shared.localizedString(for: "other"),
            englishName: "Others",
            iconName: "ellipsis.circle.fill",
            color: .gray,
            type: type
        )
        
        dataManager.addCategory(defaultCategory)
        return defaultCategory
    }
} 