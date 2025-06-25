import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedType: TransactionType = .expense
    @State private var showingAddCategory = false
    @State private var showingEditCategory = false
    @State private var editingCategory: TransactionCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: TransactionCategory?

    private var categories: [TransactionCategory] {
        selectedType == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
    }

    var body: some View {
        VStack(spacing: 0) {
            // 类型选择器
            CategoryTypeSelector(selectedType: $selectedType)

            // 添加分类按钮
            HStack {
                Spacer()
                Button(action: {
                    showingAddCategory = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(selectedType == .expense ? LocalizedString("add_category") : LocalizedString("add_category"))
                            .font(.system(.subheadline, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // 分类列表
            if categories.isEmpty {
                EmptyCategoriesView(type: selectedType)
            } else {
                List {
                    ForEach(categories, id: \.id) { category in
                        CategoryRowView(category: category)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(LocalizedString("edit")) {
                                    editCategory(category)
                                }
                                .tint(.orange)

                                Button(LocalizedString("delete"), role: .destructive) {
                                    deleteCategory(category)
                                }
                            }
                    }
                    .onMove { source, destination in
                        moveCategory(from: source, to: destination)
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddEditCategoryView(type: selectedType, category: nil)
                .environmentObject(dataManager)
                .environmentObject(TranslationService())
        }
        .sheet(isPresented: $showingEditCategory) {
            AddEditCategoryView(type: selectedType, category: editingCategory)
                .environmentObject(dataManager)
                .environmentObject(TranslationService())
        }
        .alert(LocalizedString("delete_category"), isPresented: $showingDeleteAlert) {
            Button(LocalizedString("cancel"), role: .cancel) { }
            Button(LocalizedString("delete"), role: .destructive) {
                if let category = categoryToDelete {
                    confirmDeleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                let usageCount = dataManager.transactions.filter { $0.category.id == category.id }.count
                if usageCount > 0 {
                    Text(String(format: LocalizedString("category_in_use"), usageCount) + " " + LocalizedString("delete_category_message"))
                } else {
                    Text(LocalizedString("delete_category_message"))
                }
            }
        }
    }

    private func editCategory(_ category: TransactionCategory) {
        editingCategory = category
        showingEditCategory = true
    }

    private func deleteCategory(_ category: TransactionCategory) {
        categoryToDelete = category
        showingDeleteAlert = true
    }

    private func confirmDeleteCategory(_ category: TransactionCategory) {
        // 更新使用该分类的交易记录为"未分类"
        dataManager.updateTransactionsForDeletedCategory(category)
        // 删除分类
        dataManager.deleteCategory(category)
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var items = categories
        items.move(fromOffsets: source, toOffset: destination)

        // 更新数据源
        if selectedType == .expense {
            dataManager.expenseCategories = items
        } else {
            dataManager.incomeCategories = items
        }
        dataManager.saveCategories()
    }
}