import SwiftUI

struct EmptyCategoriesView: View {
    let type: TransactionType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(String(format: LocalizedString("no_categories_of_type"), type.displayName))
                .font(.headline)
                .foregroundColor(.secondary)

            LocalizedText("tap_button_to_add_category")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}