import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: TransactionCategory?
    // 移除selectedCurrency状态，直接使用系统货币
    @State private var note: String = ""
    @State private var date = Date()

    private var categories: [TransactionCategory] {
        selectedType == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部类型选择器
                TypeSelector(selectedType: $selectedType)
                    .onChange(of: selectedType) { _ in
                        selectedCategory = nil
                    }

                ScrollView {
                    VStack(spacing: 24) {
                        // 金额输入
                        AmountInputSection(amount: $amount)
                        .environmentObject(dataManager)

                        // 分类选择
                        CategorySelectionSection(
                            categories: categories,
                            selectedCategory: $selectedCategory
                        )

                        // 备注输入
                        NoteInputSection(note: $note)

                        // 日期选择
                        DateSelectionSection(date: $date)
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // 点击空白处收回键盘
                    hideKeyboard()
                }
            }
            .navigationTitle(LocalizedString("add_transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                // 顶部左侧取消按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                // 顶部右侧保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("save")) {
                        saveTransaction()
                    }
                    .foregroundColor(isFormValid ? .blue : .gray)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            if let firstCategory = categories.first {
                selectedCategory = firstCategory
            }
        }
    }

    private var isFormValid: Bool {
        !amount.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0 &&
        selectedCategory != nil
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            currency: dataManager.currentSystemCurrency,
            type: selectedType,
            category: category,
            note: note,
            date: date
        )

        dataManager.addTransaction(transaction)
        dismiss()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}