import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: TransactionCategory?
    // 移除selectedCurrency状态，直接使用系统货币
    @State private var note: String = ""
    @State private var date = Date()
    @State private var isSaving: Bool = false

    private var categories: [TransactionCategory] {
        selectedType == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部类型选择器
                TypeSelector(selectedType: $selectedType)
                    .onChange(of: selectedType) { _ in
                        // 延迟状态更新以避免Publishing错误
                        DispatchQueue.main.async {
                            selectedCategory = nil
                        }
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
                        Task {
                            await saveTransaction()
                        }
                    }
                    .foregroundColor(isFormValid && !isSaving ? .blue : .gray)
                    .disabled(!isFormValid || isSaving)
                }
            }
            .keyboardToolbar()
        }
        .onAppear {
            // 延迟状态更新以避免Publishing错误
            DispatchQueue.main.async {
                if let firstCategory = categories.first {
                    selectedCategory = firstCategory
                }
            }
        }
    }

    private var isFormValid: Bool {
        !amount.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0 &&
        selectedCategory != nil
    }

    private func saveTransaction() async {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            return
        }

        isSaving = true
        
        // 准备备注字段和翻译标识
        var chineseNote: String? = nil
        var englishNote: String? = nil
        var isChineseNoteTranslated = false
        var isEnglishNoteTranslated = false
        
        // 如果用户输入了备注，先保存原文，然后异步翻译
        if !note.isEmpty {
            let isChineseSystem = localizationManager.currentLanguage.hasPrefix("zh")
            
            if isChineseSystem {
                // 中文系统：先保存中文原文
                chineseNote = note
                isChineseNoteTranslated = false
                isEnglishNoteTranslated = false // 先不设置为翻译，等异步翻译完成后更新
            } else {
                // 英文或其他系统：先保存英文原文
                englishNote = note
                isEnglishNoteTranslated = false
                isChineseNoteTranslated = false // 先不设置为翻译，等异步翻译完成后更新
            }
        }

        // 先创建并保存交易记录（不等待翻译）
        let transaction = Transaction(
            amount: amountValue,
            currency: dataManager.currentSystemCurrency,
            type: selectedType,
            category: category,
            note: note,
            chineseNote: chineseNote,
            englishNote: englishNote,
            date: date,
            isChineseNoteTranslated: isChineseNoteTranslated,
            isEnglishNoteTranslated: isEnglishNoteTranslated
        )

        await MainActor.run {
            dataManager.addTransaction(transaction)
            isSaving = false
            dismiss()
        }
        
        // 异步进行翻译并更新记录
        if !note.isEmpty {
            Task {
                await performAsyncTranslation(for: transaction)
            }
        }
    }
    
    // 异步翻译并更新记录
    private func performAsyncTranslation(for transaction: Transaction) async {
        let isChineseSystem = localizationManager.currentLanguage.hasPrefix("zh")
        
        do {
            var updatedChineseNote = transaction.chineseNote
            var updatedEnglishNote = transaction.englishNote
            var updatedIsChineseNoteTranslated = transaction.isChineseNoteTranslated
            var updatedIsEnglishNoteTranslated = transaction.isEnglishNoteTranslated
            
            if isChineseSystem {
                // 中文系统：翻译为英文
                updatedEnglishNote = try await translationService.translateToEnglish(note)
                updatedIsEnglishNoteTranslated = true
            } else {
                // 英文或其他系统：翻译为中文
                updatedChineseNote = try await translationService.translateText(note)
                updatedIsChineseNoteTranslated = true
            }
            
            // 更新交易记录
            let updatedTransaction = Transaction(
                id: transaction.id,
                amount: transaction.originalAmount,
                currency: transaction.originalCurrency,
                type: transaction.type,
                category: transaction.category,
                note: transaction.note,
                chineseNote: updatedChineseNote,
                englishNote: updatedEnglishNote,
                date: transaction.date,
                isChineseNoteTranslated: updatedIsChineseNoteTranslated,
                isEnglishNoteTranslated: updatedIsEnglishNoteTranslated,
                isEdited: transaction.isEdited  // 保持原有的编辑状态
            )
            
            await MainActor.run {
                dataManager.updateTransaction(originalId: transaction.id, updatedTransaction: updatedTransaction)
            }
        } catch {
            // 翻译失败，保持原有记录不变
            print("Translation failed: \(error)")
        }
    }


}