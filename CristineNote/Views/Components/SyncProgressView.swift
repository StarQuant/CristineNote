import SwiftUI

struct SyncProgressView: View {
    @ObservedObject var syncService: SyncService
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // 同步图标和状态
                VStack(spacing: 16) {
                    // 动画图标
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: syncService.syncProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: syncService.syncProgress)
                        
                        if syncService.syncProgress >= 1.0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(syncService.isShowingProgress ? 360 : 0))
                                .animation(
                                    syncService.isShowingProgress ? 
                                    Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                                    .default,
                                    value: syncService.isShowingProgress
                                )
                        }
                    }
                    
                    // 状态文本
                    Text(syncService.syncStatus.isEmpty ? syncService.syncState.displayName : syncService.syncStatus)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    // 进度百分比
                    if syncService.isShowingProgress {
                        Text("\(Int(syncService.syncProgress * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // 进度条
                if syncService.isShowingProgress {
                    ProgressView(value: syncService.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 8)
                        .scaleEffect(1.0, anchor: .center)
                        .animation(.easeInOut(duration: 0.5), value: syncService.syncProgress)
                }
                
                // 连接的设备信息
                if !syncService.connectedPeers.isEmpty {
                    VStack(spacing: 12) {
                        Text("已连接设备")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ForEach(syncService.connectedPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.blue)
                                Text(peer.displayName)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
                
                // 同步结果
                if syncService.syncResult.isSuccess && syncService.syncProgress >= 1.0 {
                    SyncResultCard(result: syncService.syncResult)
                }
                
                // 错误信息
                if !syncService.syncResult.isSuccess, let errorMessage = syncService.syncResult.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        Text("同步失败")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // 底部按钮
                if syncService.syncProgress >= 1.0 || !syncService.syncResult.isSuccess {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("完成")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                } else if syncService.isShowingProgress {
                    Button(action: {
                        syncService.stopSync()
                    }) {
                        Text("取消同步")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle(LocalizedString("data_sync"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !syncService.isShowingProgress {
                        Button("关闭") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

struct SyncResultCard: View {
    let result: SyncResult
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("同步完成")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // 统计数据
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "新增交易",
                    value: result.transactionsAdded,
                    color: .green,
                    icon: "plus.circle"
                )
                
                StatCard(
                    title: "重复交易",
                    value: result.transactionsDuplicated,
                    color: .orange,
                    icon: "exclamationmark.triangle"
                )
                
                StatCard(
                    title: "新增分类",
                    value: result.categoriesAdded,
                    color: .blue,
                    icon: "folder.badge.plus"
                )
                
                StatCard(
                    title: "重复分类",
                    value: result.categoriesDuplicated,
                    color: .gray,
                    icon: "folder.badge.questionmark"
                )
                
                StatCard(
                    title: "同步汇率",
                    value: result.exchangeRatesSynced,
                    color: .purple,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatCard(
                    title: "货币设置",
                    value: result.currencySettingsSynced ? 1 : 0,
                    color: .mint,
                    icon: "banknote"
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

struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
} 