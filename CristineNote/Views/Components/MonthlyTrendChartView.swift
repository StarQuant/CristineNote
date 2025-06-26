import SwiftUI
import Charts

struct MonthlyTrendData {
    let month: String
    let income: Double
    let expense: Double
    let balance: Double
    let date: Date
}

struct MonthlyTrendChartView: View {
    @EnvironmentObject var dataManager: DataManager
    let selectedType: TransactionType?
    
    @State private var trendData: [MonthlyTrendData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(LocalizedString("monthly_trend"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if trendData.isEmpty {
                Text(LocalizedString("no_trend_data"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .frame(alignment: .center)
            } else {
                Chart {
                    ForEach(trendData, id: \.month) { data in
                        if selectedType == nil {
                            // 显示收入、支出、结余
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.income)
                            )
                            .foregroundStyle(.green)
                            .symbol(.circle)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.expense)
                            )
                            .foregroundStyle(.red)
                            .symbol(.square)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.balance)
                            )
                            .foregroundStyle(.blue)
                            .symbol(.diamond)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        } else if selectedType == .income {
                            // 只显示收入
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.income)
                            )
                            .foregroundStyle(.green)
                            .symbol(.circle)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        } else {
                            // 只显示支出
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.expense)
                            )
                            .foregroundStyle(.red)
                            .symbol(.square)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatShortCurrency(amount))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // 图例
                if selectedType == nil {
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text(LocalizedString("income"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text(LocalizedString("expense"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Diamond()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text(LocalizedString("surplus"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .onAppear {
            loadTrendData()
        }
        .onChange(of: selectedType) { _ in
            loadTrendData()
        }
    }
    
    private func loadTrendData() {
        let calendar = Calendar.current
        let now = Date()
        var data: [MonthlyTrendData] = []
        
        // 获取最近6个月的数据
        for i in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now),
                  let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start,
                  let monthEnd = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: monthStart)!) else {
                continue
            }
            
            let income = dataManager.getTotalIncome(for: .custom, customStartDate: monthStart, customEndDate: monthEnd)
            let expense = dataManager.getTotalExpense(for: .custom, customStartDate: monthStart, customEndDate: monthEnd)
            let balance = income - expense
            
            let formatter = DateFormatter()
            formatter.dateFormat = LocalizationManager.shared.currentLanguage == "zh-Hans" ? "MM月" : "MMM"
            let monthString = formatter.string(from: monthDate)
            
            data.append(MonthlyTrendData(
                month: monthString,
                income: income,
                expense: expense,
                balance: balance,
                date: monthDate
            ))
        }
        
        trendData = data.reversed() // 按时间正序排列
    }
    
    private func formatShortCurrency(_ amount: Double) -> String {
        let currency = dataManager.currentSystemCurrency
        
        if abs(amount) >= 1000000 {
            return String(format: "%@%.1fM", currency.symbol, amount / 1000000)
        } else if abs(amount) >= 1000 {
            return String(format: "%@%.1fK", currency.symbol, amount / 1000)
        } else {
            return String(format: "%@%.0f", currency.symbol, amount)
        }
    }
}

// 钻石形状用于图例
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.closeSubpath()
        return path
    }
} 