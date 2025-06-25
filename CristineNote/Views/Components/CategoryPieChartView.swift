import SwiftUI

struct CategoryPieChartView: View {
    @EnvironmentObject var dataManager: DataManager
    let data: [(category: TransactionCategory, amount: Double)]

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedString("category_distribution"))
                .font(.headline)

            if data.isEmpty {
                EmptyAnalysisView()
            } else {
                ZStack {
                    // 简单的饼图实现
                    ForEach(Array(data.enumerated()), id: \.1.category.id) { index, item in
                        PieSlice(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            color: item.category.color
                        )
                    }
                }
                .frame(width: 200, height: 200)

                // 图例
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(data.prefix(6).enumerated()), id: \.1.category.id) { index, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 12, height: 12)

                            Text(item.category.displayName(for: dataManager))
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    private var total: Double {
        data.reduce(0) { $0 + $1.amount }
    }

    private func percentage(for index: Int) -> Double {
        guard index < data.count, total > 0 else { return 0 }
        return data[index].amount / total
    }

    private func startAngle(for index: Int) -> Angle {
        let previousSum = data.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees(previousSum / total * 360 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let currentSum = data.prefix(index + 1).reduce(0) { $0 + $1.amount }
        return .degrees(currentSum / total * 360 - 90)
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 80

            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.closeSubpath()
        }
        .fill(color)
    }
}