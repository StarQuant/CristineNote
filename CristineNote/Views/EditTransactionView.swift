import SwiftUI

struct EditTransactionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    
    @State private var selectedType: TransactionType
    @State private var amount: String
    @State private var selectedCategory: TransactionCategory?
    @State private var note: String
    @State private var chineseNote: String = ""
    @State private var englishNote: String = ""
    @State private var date: Date
    @State private var isSaving: Bool = false

    private var categories: [TransactionCategory] {
        selectedType == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
    }

    init(transaction: Transaction) {
        self.transaction = transaction
        self._selectedType = State(initialValue: transaction.type)
        self._amount = State(initialValue: String(transaction.originalAmount))
        self._selectedCategory = State(initialValue: transaction.category)
        self._note = State(initialValue: transaction.note)
        
        // 初始化中英文备注
        if let chinese = transaction.chineseNote, let english = transaction.englishNote {
            // 如果已有双语备注，直接使用
            self._chineseNote = State(initialValue: chinese)
            self._englishNote = State(initialValue: english)
        } else if !transaction.note.isEmpty {
            // 如果只有主备注，根据内容语言分配
            let containsChinese = transaction.note.range(of: "\\p{Han}", options: .regularExpression) != nil
            if containsChinese {
                self._chineseNote = State(initialValue: transaction.note)
                self._englishNote = State(initialValue: transaction.englishNote ?? "")
            } else {
                self._chineseNote = State(initialValue: transaction.chineseNote ?? "")
                self._englishNote = State(initialValue: transaction.note)
            }
        } else {
            // 如果没有备注，初始化为空
            self._chineseNote = State(initialValue: "")
            self._englishNote = State(initialValue: "")
        }
        
        self._date = State(initialValue: transaction.date)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部类型选择器
                TypeSelector(selectedType: $selectedType)
                    .onChange(of: selectedType) { _ in
                        selectedCategory = categories.first { $0.type == selectedType }
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
                        BilingualNoteInputSection(
                            note: $note,
                            chineseNote: $chineseNote,
                            englishNote: $englishNote
                        )
                        .environmentObject(translationService)
                        .environmentObject(localizationManager)

                        // 日期选择
                        DateSelectionSection(date: $date)
                    }
                    .padding()
                }
            }
            .navigationTitle(LocalizedString("edit_transaction"))
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
                
                // 键盘工具栏
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            if let firstCategory = categories.first(where: { $0.type == selectedType }) {
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



    private func saveTransaction() async {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            return
        }

        isSaving = true
        
        // 使用已有的中英文备注
        let finalChineseNote = chineseNote.isEmpty ? nil : chineseNote
        let finalEnglishNote = englishNote.isEmpty ? nil : englishNote
        
        // 判断翻译标识
        // 对于编辑，我们保持原有的翻译标识，除非备注完全改变
        var isChineseNoteTranslated = transaction.isChineseNoteTranslated
        var isEnglishNoteTranslated = transaction.isEnglishNoteTranslated
        
        // 如果中英文备注都存在，保持原有标识
        // 如果只有一个备注，根据当前系统语言设置标识
        if finalChineseNote != nil && finalEnglishNote == nil {
            // 只有中文备注
            isChineseNoteTranslated = false
            isEnglishNoteTranslated = false
        } else if finalEnglishNote != nil && finalChineseNote == nil {
            // 只有英文备注
            isEnglishNoteTranslated = false
            isChineseNoteTranslated = false
        } else if finalChineseNote != nil && finalEnglishNote != nil {
            // 有双语备注，检查是否有新的翻译
            let originalChineseNote = transaction.chineseNote ?? ""
            let originalEnglishNote = transaction.englishNote ?? ""
            
            // 如果备注内容发生变化，可能是用户手动修改或新翻译
            // 这里我们保持原有标识，除非用户明确进行了翻译操作
            // 由于编辑页面有翻译功能，我们假设如果内容变化了，保持原有的翻译状态
            if originalChineseNote != chineseNote {
                // 中文备注变化了，检查是否可能是翻译产生的
                // 这里保持原有逻辑
            }
            if originalEnglishNote != englishNote {
                // 英文备注变化了，检查是否可能是翻译产生的
                // 这里保持原有逻辑
            }
        }

        let updatedTransaction = Transaction(
            amount: amountValue,
            currency: dataManager.currentSystemCurrency,
            type: selectedType,
            category: category,
            note: note,
            chineseNote: finalChineseNote,
            englishNote: finalEnglishNote,
            date: date,
            isChineseNoteTranslated: isChineseNoteTranslated,
            isEnglishNoteTranslated: isEnglishNoteTranslated,
            isEdited: true  // 标记为已编辑
        )

        await MainActor.run {
            dataManager.updateTransaction(originalId: transaction.id, updatedTransaction: updatedTransaction)
            isSaving = false
            dismiss()
        }
    }
} 