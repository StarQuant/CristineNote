import SwiftUI

struct CategorySelectionSection: View {
    let categories: [TransactionCategory]
    @Binding var selectedCategory: TransactionCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("category"))
                .font(.system(.headline, weight: .semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(categories, id: \.id) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}