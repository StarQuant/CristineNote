import SwiftUI

struct DateSelectionSection: View {
    @Binding var date: Date
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("date"))
                .font(.system(.headline, weight: .semibold))

            DatePicker(LocalizedString("date"), selection: $date, displayedComponents: [.date])
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.locale, Locale(identifier: localizationManager.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US"))
        }
    }
}