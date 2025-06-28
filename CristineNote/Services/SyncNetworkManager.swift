import Foundation
@preconcurrency import MultipeerConnectivity
import SwiftUI
import Network
import CoreLocation

@MainActor
class SyncNetworkManager: NSObject, ObservableObject {
    private var serviceType: String  // 动态生成服务类型以避免冲突
    private var peerId: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var retryCount = 0
    private let maxRetries = 5  // 增加重试次数
    private var currentDeviceInfo: DeviceInfo?
    private var lastAdvertiserStopTime: Date?
    private var isResetting = false  // 防止重置过程中的重复操作
    private var componentId = UUID()  // 用于跟踪组件生命周期
    private var targetDeviceInfo: QRCodeData?  // 目标设备信息（用于扫码后的自动连接）
    
    @Published var syncState: SyncState = .idle
    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredPeers: [MCPeerID] = []
    
    // 回调闭包
    var onDataReceived: ((Data, MCPeerID) -> Void)?
    var onConnectionStateChanged: ((MCSessionState, MCPeerID) -> Void)?
    var onSyncStateChanged: ((SyncState) -> Void)?
    
    override init() {
        // 使用Apple官方示例中的标准格式
        self.serviceType = "mpc-note"  // 符合MultipeerConnectivity命名规范
        
        // 使用简单的设备名称
        self.peerId = MCPeerID(displayName: "CNote")
        
        // 创建最基础的会话配置
        self.session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
        
        super.init()
        
        // 设置会话代理
        session.delegate = self
        
        
        // 检查网络权限
        checkNetworkPrivacyPermissions()
    }
    
    // MARK: - 私有辅助方法
    
    /// 设置同步状态并通知观察者
    private func setSyncState(_ newState: SyncState) {
        print("SyncNetworkManager.setSyncState: \(syncState) -> \(newState)")
        syncState = newState
        onSyncStateChanged?(newState)
    }
    
    /// 检查网络隐私权限
    private func checkNetworkPrivacyPermissions() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                    } else if path.usesInterfaceType(.cellular) {
                    }
                } else {
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        // 1秒后停止监听
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            monitor.cancel()
        }
    }
    
    // MARK: - 公共方法
    
    /// 开始广播服务（生成二维码模式）
    func startAdvertising(with deviceInfo: DeviceInfo) {
        currentDeviceInfo = deviceInfo  // 保存设备信息用于重试
        retryCount = 0  // 重置重试计数
        
        // 先请求必要的权限
        requestNetworkPermissions { [weak self] granted in
            if granted {
                self?.testBonjourSupport { isSupported in
                    if isSupported {
                        self?.internalStartAdvertising(with: deviceInfo)
                    } else {
                        self?.setSyncState(.failed(SyncError.networkServiceUnavailable))
                    }
                }
            } else {
                self?.setSyncState(.failed(SyncError.networkServiceUnavailable))
            }
        }
    }
    
    /// 请求网络权限
    private func requestNetworkPermissions(completion: @escaping (Bool) -> Void) {
        
        // 对于iOS 14+，本地网络权限会在首次使用MultipeerConnectivity时自动弹出
        // 我们这里主要检查位置权限（用于WiFi信息访问）
        let locationManager = CLLocationManager()
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // 创建一个临时的位置管理器来请求权限
            let tempLocationManager = CLLocationManager()
            
            class LocationDelegate: NSObject, CLLocationManagerDelegate {
                let completion: (Bool) -> Void
                
                init(completion: @escaping (Bool) -> Void) {
                    self.completion = completion
                }
                
                func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
                    let granted = status == .authorizedWhenInUse || status == .authorizedAlways
                    DispatchQueue.main.async { [completion] in
                        completion(granted || status == .denied) // 即使拒绝位置权限，也允许继续尝试
                    }
                }
            }
            
            let delegate = LocationDelegate(completion: completion)
            tempLocationManager.delegate = delegate
            tempLocationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            completion(true)
            
        case .denied, .restricted:
            completion(true) // 即使没有位置权限，也允许尝试MultipeerConnectivity
            
        @unknown default:
            completion(true)
        }
    }
    
    /// 测试Bonjour服务支持 - 简化版本
    private func testBonjourSupport(completion: @escaping (Bool) -> Void) {
        // 由于iOS系统限制复杂，直接尝试启动实际服务
        completion(true)
    }
    
    private func internalStartAdvertising(with deviceInfo: DeviceInfo) {
        // 防止在重置过程中启动
        guard !isResetting else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.internalStartAdvertising(with: deviceInfo)
            }
            return
        }
        
        // 彻底重置所有状态
        resetForRetry()
        
        // 重置后获取新的componentId
        let currentId = componentId
        
        // 延迟启动，给系统足够时间清理之前的资源
        let delay = 6.0 + Double(retryCount) * 3.0  // 进一步增加延迟时间
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            // 如果componentId已经改变，说明已经被重置，应该取消这个延迟任务
            guard currentId == self.componentId else {
                print("Cancelling delayed advertising task - componentId changed")
                return
            }
            
            
            // 为每次重试创建完全新的组件和标识符
            let timestamp = Int(Date().timeIntervalSince1970) % 10000
            self.peerId = MCPeerID(displayName: "C\(timestamp)")
            
            // 重新创建session（确保完全新的实例）
            self.session = MCSession(
                peer: self.peerId, 
                securityIdentity: nil, 
                encryptionPreference: .none
            )
            self.session.delegate = self
            
            // 等待一小段时间确保session完全初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 这里self不是可选，直接用self
                
                // 创建新的advertiser（使用最简配置）
                self.advertiser = MCNearbyServiceAdvertiser(
                    peer: self.peerId,
                    discoveryInfo: nil,  
                    serviceType: self.serviceType
                )
                
                guard let advertiser = self.advertiser else {
                    self.setSyncState(.failed(SyncError.networkServiceUnavailable))
                    return
                }
                
                advertiser.delegate = self
                
                
                // 使用异步启动，避免阻塞主线程
                Task {
                    advertiser.startAdvertisingPeer()
                    await MainActor.run {
                        self.setSyncState(.advertising)
                    }
                }
            }
        }
    }
    

    /// 设置目标设备信息（从二维码扫描获得）
    func setTargetDevice(_ qrCodeData: QRCodeData) {
        targetDeviceInfo = qrCodeData
        print("SyncNetworkManager: Set target device: \(qrCodeData.deviceName)")
    }
    
    /// 开始搜索设备（扫描二维码模式）
    func startBrowsing(useDelay: Bool = true) {
        let currentId = componentId
        
        // 防止在重置过程中启动
        guard !isResetting else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.startBrowsing(useDelay: useDelay)
            }
            return
        }
        
        if useDelay {
            // 彻底重置状态
            resetForRetry()
            
            // 延迟启动以确保服务完全停止
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self else { return }
                // 如果componentId已经改变，说明已经被重置，应该取消这个延迟任务
                guard currentId == self.componentId else {
                    print("Cancelling delayed browsing task - componentId changed")
                    return
                }
                self.performBrowsing()
            }
        } else {
            // 立即启动（用于扫码后的连接）
            performBrowsing()
        }
    }
    
    private func performBrowsing() {
        // 为浏览模式创建新的peer ID
        let timestamp = Int(Date().timeIntervalSince1970) % 10000
        self.peerId = MCPeerID(displayName: "S\(timestamp)")
        
        // 重新创建session
        self.session = MCSession(
            peer: self.peerId, 
            securityIdentity: nil, 
            encryptionPreference: .none
        )
        self.session.delegate = self
        
        // 等待session初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 创建新的browser
            self.browser = MCNearbyServiceBrowser(
                peer: self.peerId, 
                serviceType: self.serviceType
            )
            
            guard let browser = self.browser else {
                self.setSyncState(.failed(SyncError.networkServiceUnavailable))
                return
            }
            
            browser.delegate = self
            
            // 使用异步启动
            Task {
                browser.startBrowsingForPeers()
                await MainActor.run {
                    self.setSyncState(.browsing)
                }
            }
        }
    }
    
    /// 连接到指定设备
    func connectTo(peer: MCPeerID) {
        guard let browser = browser else { return }
        
        let context = Data() // 可以传递额外的连接信息
        browser.invitePeer(peer, to: session, withContext: context, timeout: 30)
        
        setSyncState(.connecting)
    }
    
    /// 发送数据
    func sendData(_ data: Data, to peers: [MCPeerID]? = nil) throws {
        let targetPeers = peers ?? connectedPeers
        guard !targetPeers.isEmpty else {
            throw SyncError.noPeersConnected
        }
        
        try session.send(data, toPeers: targetPeers, with: .reliable)
    }
    
    /// 发送同步消息
    func sendSyncMessage(type: SyncMessageType, payload: Data, to peers: [MCPeerID]? = nil) throws {
        let message = SyncMessage(type: type, payload: payload)
        let messageData = try JSONEncoder().encode(message)
        try sendData(messageData, to: peers)
    }
    
    /// 停止所有服务
    func stopAll() {
        print("SyncNetworkManager.stopAll() called")
        
        // 停止广播服务
        if let currentAdvertiser = advertiser {
            currentAdvertiser.stopAdvertisingPeer()
            advertiser = nil
            lastAdvertiserStopTime = Date()
        }
        
        // 停止搜索服务
        if let currentBrowser = browser {
            currentBrowser.stopBrowsingForPeers()
            browser = nil
        }
        
        // 断开会话
        if !session.connectedPeers.isEmpty {
            session.disconnect()
        }
        
        // 清理状态
        connectedPeers.removeAll()
        discoveredPeers.removeAll()
        
        // 更新componentId以取消所有延迟任务
        componentId = UUID()
        print("Updated componentId to cancel delayed tasks")
        
        if case .failed = syncState {
            // 保持错误状态
        } else {
            setSyncState(.idle)
        }
        
    }
    
    /// 彻底重置所有状态（用于重试）
    private func resetForRetry() {
        guard !isResetting else {
            return
        }
        
        isResetting = true
        
        // 强制停止所有服务，忽略可能的错误
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        // 断开会话连接
        session.disconnect()
        
        // 清理所有状态
        connectedPeers.removeAll()
        discoveredPeers.removeAll()
        
        // 生成新的组件ID
        componentId = UUID()
        
        
        // 延迟重置标志，确保操作完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isResetting = false
        }
    }
    
    /// 断开连接
    func disconnect() {
        session.disconnect()
        setSyncState(.idle)
    }
    
    /// 重试最后一次操作
    func retryLastOperation() {
        if let deviceInfo = currentDeviceInfo {
            // 重置重试计数，重新开始
            retryCount = 0
            startAdvertising(with: deviceInfo)
        }
    }
    
    /// 完全重置网络管理器状态
    func resetCompletely() {
        
        // 防止重复重置
        guard !isResetting else {
            return
        }
        
        isResetting = true
        
        // 强制停止所有服务
        DispatchQueue.main.async {
            // 停止advertiser
            if let advertiser = self.advertiser {
                advertiser.stopAdvertisingPeer()
                self.advertiser = nil
            }
            
            // 停止browser
            if let browser = self.browser {
                browser.stopBrowsingForPeers()
                self.browser = nil
            }
            
            // 断开session
            self.session.disconnect()
            
            // 清理状态
            self.connectedPeers.removeAll()
            self.discoveredPeers.removeAll()
            
            // 重置计数器和缓存
            self.retryCount = 0
            self.currentDeviceInfo = nil
            self.lastAdvertiserStopTime = nil
            
            // 生成全新的组件ID
            self.componentId = UUID()
            
            // 重新创建基础组件
            let baseTimestamp = Int(Date().timeIntervalSince1970) % 1000
            self.peerId = MCPeerID(displayName: "CNote\(baseTimestamp)")
            self.session = MCSession(
                peer: self.peerId,
                securityIdentity: nil,
                encryptionPreference: .none
            )
            self.session.delegate = self
            
            // 重置服务类型为默认值
            self.serviceType = "mpc-note"
            
            // 重置到初始状态
            self.setSyncState(.idle)
            
            
            // 延迟重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isResetting = false
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func handleReceivedData(_ data: Data, from peer: MCPeerID) {
        onDataReceived?(data, peer)
    }
    
    /// 尝试替代连接方法（解决Bonjour冲突）
    private func attemptAlternativeConnection() {
        
        // 始终使用固定服务类型，避免随机名
        self.serviceType = "mpc-note"
        
        // 使用极简配置重新尝试
        let simpleTimestamp = Int(Date().timeIntervalSince1970) % 1000
        let simplePeerName = "S\(simpleTimestamp)"
        
        // 重新创建所有组件
        self.peerId = MCPeerID(displayName: simplePeerName)
        self.session = MCSession(peer: self.peerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
        
        // 使用最简配置的advertiser
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: self.peerId,
            discoveryInfo: [:],  // 空的discovery info
            serviceType: self.serviceType
        )
        
        self.advertiser?.delegate = self
        
        // 延迟启动以确保系统准备就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advertiser?.startAdvertisingPeer()
            self.setSyncState(.advertising)
        }
    }
    
}

// MARK: - MCSessionDelegate
extension SyncNetworkManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.setSyncState(.connected)
                
            case .connecting:
                self.setSyncState(.connecting)
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.connectedPeers.isEmpty {
                    self.setSyncState(.idle)
                }
            @unknown default:
                break
            }
            
            self.onConnectionStateChanged?(state, peerID)
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(data, from: peerID)
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 暂不处理流数据
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 暂不处理资源传输
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 暂不处理资源传输
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension SyncNetworkManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                invitationHandler(false, nil)
                return
            }
            
            
            // 自动接受连接请求
            invitationHandler(true, self.session)
            self.setSyncState(.connecting)
        }
    }
    
        nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let nsError = error as NSError
            let errorDescription = error.localizedDescription.lowercased()
            
            
            // 检测"invalid reuse"错误
            if errorDescription.contains("invalid reuse") || errorDescription.contains("initialization failure") {
                self.setSyncState(.failed(SyncError.componentReuseError))
                return
            }
            
            // 打印系统诊断信息
            
            // 处理特定的网络服务错误 -72008
            if nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
                self.retryCount += 1
                
                if self.retryCount <= 3 {  // 增加重试次数
                    
                    // 不调用stopAll()以避免重置retryCount
                    // 直接重置状态
                    self.resetForRetry()
                    
                    let retryDelay = Double(self.retryCount) * 3.0 + 5.0  // 增加延迟
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                        if let deviceInfo = self.currentDeviceInfo {
                            // 保持重试计数不变
                            self.internalStartAdvertising(with: deviceInfo)
                        }
                    }
                } else {
                    
                    // 广播失败后，自动切换到浏览模式
                    self.setSyncState(.failed(SyncError.networkServiceUnavailable))
                    
                    // 通知用户需要使用浏览模式
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    }
                }
            } else {
                self.setSyncState(.failed(SyncError.networkError(error)))
            }
        }
    }
    


}

// MARK: - MCNearbyServiceBrowserDelegate
extension SyncNetworkManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
                print("Found peer: \(peerID.displayName)")
                
                // 如果有目标设备信息，尝试智能匹配
                if let targetDevice = self.targetDeviceInfo {
                    // 由于PeerID是动态生成的，我们先连接然后在连接后验证设备信息
                    print("Attempting to connect to peer \(peerID.displayName) for target device \(targetDevice.deviceName)")
                    self.connectTo(peer: peerID)
                } else {
                    // 没有目标设备信息，连接第一个发现的设备
                    if self.discoveredPeers.count == 1 {
                        self.connectTo(peer: peerID)
                    }
                }
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.discoveredPeers.removeAll { $0 == peerID }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.syncState = .failed(error)
        }
    }
}

// MARK: - 扩展
extension MCSessionState {
    var description: String {
        switch self {
        case .notConnected: return "未连接"
        case .connecting: return "连接中"
        case .connected: return "已连接"
        @unknown default: return "未知状态"
        }
    }
}

// MARK: - 同步错误
enum SyncError: LocalizedError {
    case noPeersConnected
    case encodingFailed
    case decodingFailed
    case networkError(Error)
    case networkServiceUnavailable
    case bonjourServiceConflict
    case invalidData
    case componentReuseError
    
    var errorDescription: String? {
        switch self {
        case .noPeersConnected:
            return "没有连接的设备"
        case .encodingFailed:
            return "数据编码失败"
        case .decodingFailed:
            return "数据解码失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .networkServiceUnavailable:
            return "网络服务不可用，请检查网络权限或重启应用"
        case .bonjourServiceConflict:
            return "网络服务冲突，请稍后重试或重启应用。如果问题持续，请检查是否有其他应用占用网络服务。"
        case .invalidData:
            return "无效的数据格式"
        case .componentReuseError:
            return "网络组件重用错误，请点击重置按钮重新初始化网络服务。"
        }
    }
} 