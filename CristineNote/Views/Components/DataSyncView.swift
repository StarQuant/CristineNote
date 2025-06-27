import SwiftUI
import AVFoundation

struct DataSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var syncService: SyncService
    @State private var selectedMode: SyncMode = .generate
    @State private var showingQRScanner = false
    @State private var showingProgress = false
    @State private var showingPermissionAlert = false
    @State private var deviceInfo = DeviceInfo()
    @State private var isGeneratingQR = false
    
    init(dataManager: DataManager) {
        self._syncService = StateObject(wrappedValue: SyncService(dataManager: dataManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题区域 - 移除重复的"数据同步"标题
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(LocalizedString("sync_description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    
                    // 数据统计
                    DataStatsCard(dataManager: dataManager)
                    
                    // 同步模式选择
                    VStack(spacing: 16) {
                        Text(LocalizedString("choose_sync_method"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            
                        HStack(spacing: 16) {
                            SyncModeCard(
                                mode: .generate,
                                isSelected: selectedMode == .generate,
                                onTap: { selectedMode = .generate }
                            )
                            
                            SyncModeCard(
                                mode: .scan,
                                isSelected: selectedMode == .scan,
                                onTap: { selectedMode = .scan }
                            )
                        }
                    }
                    
                    // 开始同步按钮
                    Button(action: {
                        startSync()
                    }) {
                        HStack {
                            if isGeneratingQR && selectedMode == .generate {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text(LocalizedString("waiting_connection"))
                            } else {
                                Image(systemName: selectedMode == .generate ? "qrcode" : "qrcode.viewfinder")
                                Text(selectedMode == .generate ? LocalizedString("generate_qr_code") : LocalizedString("scan_qr_code"))
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((syncService.syncState == .idle && !isGeneratingQR) ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(syncService.syncState != .idle || isGeneratingQR)
                    
                    // 同步状态显示 - 使用动画平滑过渡
                    Group {
                        if syncService.syncState != .idle {
                            SyncStatusCard(syncService: syncService)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: syncService.syncState)
                    
                    // 说明文字
                    VStack(spacing: 8) {
                        Text(LocalizedString("sync_tips_wifi"))
                        Text(LocalizedString("sync_tips_security"))
                        Text(LocalizedString("sync_tips_duplicate"))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                }
            }
            .padding()
            .navigationTitle(LocalizedString("data_sync"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        syncService.stopSync()
                        resetGeneratingState()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingQRScanner) {
            QRCodeScannerView(isPresented: $showingQRScanner) { qrCodeData in
                DispatchQueue.main.async {
                    handleQRCodeDetected(qrCodeData)
                }
            }
        }
        .sheet(isPresented: $showingProgress) {
            SyncProgressView(syncService: syncService, isPresented: $showingProgress)
        }
        .fullScreenCover(isPresented: $isGeneratingQR) {
            NavigationView {
                QRCodeGeneratorView(deviceInfo: deviceInfo) { qrGenerated in
                    // 二维码生成完成后，不要关闭界面，等待连接
                    print("QR Code generated: \(qrGenerated)")
                    // 移除自动关闭逻辑，保持界面打开等待连接
                }
                .navigationTitle(LocalizedString("waiting_connection"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(LocalizedString("cancel")) {
                            syncService.stopSync()
                            resetGeneratingState()
                        }
                    }
                }
            }
        }
        .alert(LocalizedString("camera_permission_needed"), isPresented: $showingPermissionAlert) {
            Button(LocalizedString("settings")) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button(LocalizedString("cancel"), role: .cancel) { }
        } message: {
            Text(LocalizedString("camera_permission_message"))
        }
        .onChange(of: syncService.syncState) { newState in
            print("Sync state changed to: \(newState)")
            switch newState {
            case .connected:
                showingProgress = true
                // 连接成功后立即关闭QR生成界面
                isGeneratingQR = false
                print("Connection successful, closing QR view")
            case .failed, .completed, .idle:
                resetGeneratingState()
            default:
                break
            }
        }
        .onChange(of: syncService.isShowingProgress) { isShowing in
            showingProgress = isShowing
        }
        .onAppear {
            deviceInfo = DeviceInfo()
            // 每次出现时重置状态
            resetGeneratingState()
            // 完全重置同步服务
            syncService.resetCompletely()
        }
    }
    
    private func resetGeneratingState() {
        print("Resetting generating state")
        isGeneratingQR = false
    }
    
    private func startSync() {
        print("Starting sync with mode: \(selectedMode)")
        
        // 确保先重置状态
        syncService.reset()
        
        switch selectedMode {
        case .generate:
            // 重置设备信息并显示生成状态
            deviceInfo = DeviceInfo()
            isGeneratingQR = true
            print("Set isGeneratingQR to true, starting generate mode")
            syncService.startGenerateMode()
            
        case .scan:
            checkCameraPermission { granted in
                if granted {
                    showingQRScanner = true
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func handleQRCodeDetected(_ qrCodeData: QRCodeData) {
        showingQRScanner = false
        
        // 添加短暂延迟，确保sheet完全关闭后再开始同步
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            syncService.startScanMode()
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

struct DataStatsCard: View {
    let dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizedString("local_data_overview"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatItem(
                    title: LocalizedString("transaction_records"),
                    value: "\(dataManager.transactions.count)",
                    icon: "list.bullet.rectangle",
                    color: .blue
                )
                
                StatItem(
                    title: LocalizedString("expense_categories"),
                    value: "\(dataManager.expenseCategories.count)",
                    icon: "folder.fill",
                    color: .red
                )
                
                StatItem(
                    title: LocalizedString("income_categories"), 
                    value: "\(dataManager.incomeCategories.count)",
                    icon: "folder.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SyncModeCard: View {
    let mode: SyncMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: mode == .generate ? "qrcode" : "qrcode.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(mode == .generate ? LocalizedString("generate_qr_code") : LocalizedString("scan_qr_code"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(mode == .generate ? LocalizedString("generate_mode_description") : LocalizedString("scan_mode_description"))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SyncStatusCard: View {
    @ObservedObject var syncService: SyncService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: getStatusIcon())
                    .foregroundColor(getStatusColor())
                Text(LocalizedString("sync_status"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Text(syncService.syncState.displayName)
                    .foregroundColor(.secondary)
                Spacer()
                
                if syncService.syncState == .advertising || syncService.syncState == .browsing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // 错误处理显示
            if case .failed(let error) = syncService.syncState {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(LocalizedString("error_details"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 根据错误类型提供具体的解决建议
                    if let syncError = error as? SyncError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("solutions"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            
                            switch syncError {
                            case .bonjourServiceConflict:
                                Text(LocalizedString("wait_and_retry"))
                                Text(LocalizedString("close_other_apps"))
                                Text(LocalizedString("restart_wifi"))
                            case .componentReuseError:
                                Text(LocalizedString("click_reset_button"))
                                Text(LocalizedString("restart_app_if_persist"))
                                Text(LocalizedString("check_ios_version"))
                            case .networkServiceUnavailable:
                                Text(LocalizedString("check_network_permissions"))
                                Text(LocalizedString("restart_wifi_bluetooth"))
                                Text(LocalizedString("click_reset_button"))
                            default:
                                Text(LocalizedString("wait_and_retry"))
                                Text(LocalizedString("check_network_connection"))
                                Text(LocalizedString("click_reset_button"))
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 12) {
                        Button(LocalizedString("retry")) {
                            syncService.retryLastOperation()
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle)
                        
                        Button(LocalizedString("reset")) {
                            syncService.resetCompletely()
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle)
                        .foregroundColor(.orange)
                    }
                }
            }
            
            if !syncService.connectedPeers.isEmpty {
                ForEach(syncService.connectedPeers, id: \.self) { peer in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已连接: \(peer.displayName)")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func getStatusIcon() -> String {
        switch syncService.syncState {
        case .idle: return "info.circle.fill"
        case .advertising, .browsing: return "antenna.radiowaves.left.and.right"
        case .connecting: return "wifi.circle.fill"
        case .connected: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
    
    private func getStatusColor() -> Color {
        switch syncService.syncState {
        case .idle: return .blue
        case .advertising, .browsing: return .orange
        case .connecting: return .blue
        case .connected: return .green
        case .syncing: return .orange
        case .failed: return .red
        case .completed: return .green
        }
    }
} 