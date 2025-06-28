import SwiftUI

struct SyncProgressView: View {
    @ObservedObject var syncService: SyncService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var isPresented: Bool
    @State private var syncStarted = false
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 主同步界面
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if syncService.syncState == .connected && !syncStarted && !syncService.isShowingProgress {
                        // 连接成功后的开始页面
                        StartSyncView(syncService: syncService, syncStarted: $syncStarted)
                    } else if syncStarted || syncService.isShowingProgress {
                        // 同步进行中页面
                        SyncInProgressView(syncService: syncService)
                    } else {
                        // 连接中页面
                        ConnectingSyncView(syncService: syncService)
                    }
                    
                    // 右上角关闭按钮（仅在同步完成后显示）
                    if syncService.syncProgress >= 1.0 {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    // 关闭同步完成界面时断开连接
                                    syncService.stopSync()
                                    isPresented = false
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .gesture(
            // 向下滑动关闭手势（仅在同步完成后可用）
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if syncService.syncProgress >= 1.0 {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    if syncService.syncProgress >= 1.0 && value.translation.height > 100 {
                        // 下滑关闭同步完成界面时断开连接
                        syncService.stopSync()
                        isPresented = false
                    }
                }
        )
        .onChange(of: syncService.isShowingProgress) { isShowing in
            if isShowing {
                syncStarted = true
            }
        }
    }
}

// MARK: - 连接成功后的开始页面
struct StartSyncView: View {
    @ObservedObject var syncService: SyncService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var syncStarted: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 连接成功提示
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text(LocalizationManager.shared.localizedString(for: "connection_successful"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if !syncService.connectedPeers.isEmpty {
                    Text(syncService.connectedPeers.first?.displayName ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 大圆圈开始按钮
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Button(action: {
                    startSync()
                }) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 160, height: 160)
                        .overlay(
                            Text(LocalizationManager.shared.localizedString(for: "start_sync"))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        )
                }
                .scaleEffect(syncStarted ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: syncStarted)
            }
            
            // 动态提示文字
            if syncService.isShowingProgress {
                Text(LocalizationManager.shared.localizedString(for: "other_device_started_sync"))
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            } else {
                Text(LocalizationManager.shared.localizedString(for: "tap_start_sync"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(40)
    }
    
    private func startSync() {
        syncStarted = true
        syncService.startDataSync()
    }
}

// MARK: - 连接中页面
struct ConnectingSyncView: View {
    @ObservedObject var syncService: SyncService
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 连接动画
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(syncService.syncState == .connecting ? 360 : 0))
                    .animation(
                        syncService.syncState == .connecting ? 
                        Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                        .default,
                        value: syncService.syncState == .connecting
                    )
                
                Image(systemName: "wifi")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text(syncService.syncState.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !syncService.syncStatus.isEmpty {
                    Text(syncService.syncStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(40)
    }
}

// MARK: - 同步进行中页面
struct SyncInProgressView: View {
    @ObservedObject var syncService: SyncService
    @State private var animationRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 同步进度圆圈
            ZStack {
                // 背景圆圈
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 250, height: 250)
                
                // 进度光环
                Circle()
                    .trim(from: 0, to: syncService.syncProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan, .blue]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: syncService.syncProgress)
                
                // 中心百分比显示
                VStack(spacing: 8) {
                    if syncService.syncProgress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("100%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text("\(Int(syncService.syncProgress * 100))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(LocalizationManager.shared.localizedString(for: "syncing"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 状态文本
            VStack(spacing: 8) {
                if syncService.syncProgress >= 1.0 {
                    Text(LocalizationManager.shared.localizedString(for: "sync_completed"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    if syncService.syncResult.isSuccess {
                        SyncCompletionSummary(result: syncService.syncResult)
                    }
                } else {
                    Text(syncService.syncStatus.isEmpty ? syncService.syncState.displayName : syncService.syncStatus)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // 完成后的提示
            if syncService.syncProgress >= 1.0 {
                VStack(spacing: 12) {
                    Text(LocalizationManager.shared.localizedString(for: "swipe_down_to_close"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(40)
    }
}

// MARK: - 同步完成摘要
struct SyncCompletionSummary: View {
    let result: SyncResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                SummaryItem(
                    title: LocalizationManager.shared.localizedString(for: "new_transactions"),
                    value: result.transactionsAdded,
                    color: .green
                )
                
                if result.categoriesAdded > 0 {
                    SummaryItem(
                        title: LocalizationManager.shared.localizedString(for: "new_categories"),
                        value: result.categoriesAdded,
                        color: .blue
                    )
                }
                
                if result.exchangeRatesSynced > 0 {
                    SummaryItem(
                        title: LocalizationManager.shared.localizedString(for: "exchange_rates"),
                        value: result.exchangeRatesSynced,
                        color: .purple
                    )
                }
            }
            
            if result.transactionsDuplicated > 0 || result.categoriesDuplicated > 0 {
                HStack(spacing: 20) {
                    if result.transactionsDuplicated > 0 {
                        SummaryItem(
                            title: LocalizationManager.shared.localizedString(for: "duplicate_transactions"),
                            value: result.transactionsDuplicated,
                            color: .orange
                        )
                    }
                    
                    if result.categoriesDuplicated > 0 {
                        SummaryItem(
                            title: LocalizationManager.shared.localizedString(for: "duplicate_categories"),
                            value: result.categoriesDuplicated,
                            color: .gray
                        )
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

struct SummaryItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
} 