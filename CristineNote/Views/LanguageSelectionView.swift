import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    private let languages = [
        ("zh-Hans", "chinese"),
        ("en", "english")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.0) { languageCode, languageName in
                    Button(action: {
                        dataManager.setLanguage(languageCode)
                        dismiss()
                    }) {
                        HStack {
                            LocalizedText(languageName)

                            Spacer()

                            if dataManager.currentLanguage == languageCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .localizedNavigationTitle("select_language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    LocalizedButton("done") {
                        dismiss()
                    }
                }
            }
        }
    }
}