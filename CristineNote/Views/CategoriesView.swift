import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedType: TransactionType = .expense
    @State private var showingAddCategory = false
    @State private var editingCategory: TransactionCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: TransactionCategory?

    private var categories: [TransactionCategory] {
        selectedType == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
    }

    var body: some View {
        VStack(spacing: 0) {
            // 添加分类按钮 - 移到第一行
            HStack {
                Spacer()
                Button(action: {
                    // 确保编辑分类的sheet已关闭
                    editingCategory = nil
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
            .padding(.top, 8)
            .padding(.bottom, 12)

            // 类型选择器 - 移到第二行
            CategoryTypeSelector(selectedType: $selectedType)

            // 分类列表
            if categories.isEmpty {
                EmptyCategoriesView(type: selectedType)
            } else {
                List {
                    ForEach(categories, id: \.id) { category in
                        CategoryRowView(category: category)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // 编辑按钮
                                Button(action: {
                                    editCategory(category)
                                }) {
                                    Image(systemName: "pencil")
                                }
                                .tint(.orange)

                                // 删除按钮
                                Button(action: {
                                    deleteCategory(category)
                                }) {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
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
                .environmentObject(localizationManager)
        }
        .sheet(item: $editingCategory) { category in
            AddEditCategoryView(type: selectedType, category: category)
                .environmentObject(dataManager)
                .environmentObject(TranslationService())
                .environmentObject(localizationManager)
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
        // 确保添加分类的sheet已关闭
        showingAddCategory = false
        // 设置编辑分类
        editingCategory = category
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