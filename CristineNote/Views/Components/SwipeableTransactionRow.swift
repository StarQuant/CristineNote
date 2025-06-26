import SwiftUI

struct SwipeableTransactionRow: View {
    let transaction: Transaction
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // 背景删除按钮
            HStack {
                Spacer()
                Button(action: {
                    print("删除按钮被点击")
                    onDelete()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("删除")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }
            
            // 前景交易行
            HStack {
                TransactionRowView(transaction: transaction)
                    .onTapGesture {
                        onTap()
                    }
                Spacer(minLength: 0)
            }
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation < 0 { // 只允许向左滑动
                            offset = max(translation, -deleteButtonWidth)
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        let velocity = value.velocity.width
                        
                        withAnimation(.easeOut(duration: 0.3)) {
                            if translation < -deleteButtonWidth/2 || velocity < -500 {
                                // 显示删除按钮
                                offset = -deleteButtonWidth
                                showingDeleteButton = true
                            } else {
                                // 回到原位
                                offset = 0
                                showingDeleteButton = false
                            }
                        }
                    }
            )
        }
        .clipped()
        .onTapGesture {
            if showingDeleteButton {
                // 如果删除按钮显示中，点击空白处收起
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = 0
                    showingDeleteButton = false
                }
            }
        }
    }
} 