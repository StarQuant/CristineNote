import SwiftUI

struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(LocalizedString("start_date"), selection: $startDate, displayedComponents: [.date])
                        .environment(\.locale, Locale(identifier: localizationManager.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US"))
                    DatePicker(LocalizedString("end_date"), selection: $endDate, displayedComponents: [.date])
                        .environment(\.locale, Locale(identifier: localizationManager.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US"))
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            LocalizedText("selected_range")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .localizedNavigationTitle("custom_date_range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LocalizedButton("cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    LocalizedButton("done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // 确保结束日期不早于开始日期
            if endDate < startDate {
                endDate = startDate
            }
        }
        .onChange(of: startDate) { newStartDate in
            // 如果开始日期晚于结束日期，自动调整结束日期
            if newStartDate > endDate {
                endDate = newStartDate
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US")
        return formatter.string(from: date)
    }
}