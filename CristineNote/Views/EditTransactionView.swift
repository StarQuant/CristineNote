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
    
    // 跟踪翻译状态
    @State private var chineseNoteWasTranslated: Bool = false
    @State private var englishNoteWasTranslated: Bool = false
    
    // 焦点状态
    @FocusState private var amountFieldFocused: Bool

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
        
        // 初始化翻译状态
        self._chineseNoteWasTranslated = State(initialValue: transaction.isChineseNoteTranslated)
        self._englishNoteWasTranslated = State(initialValue: transaction.isEnglishNoteTranslated)
        
        self._date = State(initialValue: transaction.date)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部类型选择器
                TypeSelector(selectedType: $selectedType)
                    .onChange(of: selectedType) { _ in
                        // 检查当前选择的分类是否匹配新类型，如果不匹配才切换到默认分类
                        if let currentCategory = selectedCategory, currentCategory.type == selectedType {
                            // 当前分类类型匹配，保持不变
                            return
                        } else {
                            // 当前分类不匹配或为空，选择该类型的第一个分类
                            selectedCategory = categories.first { $0.type == selectedType }
                        }
                    }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            // 金额输入
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedString("amount"))
                                    .font(.system(.headline, weight: .semibold))

                                HStack {
                                    // 显示当前系统货币符号，不可选择
                                    Text(dataManager.currentSystemCurrency.symbol)
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 8)

                                    TextField(LocalizedString("enter_amount"), text: $amount)
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .focused($amountFieldFocused)
                                        .onChange(of: amountFieldFocused) { focused in
                                            if focused {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    proxy.scrollTo("amountSection", anchor: .center)
                                                }
                                            }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            .id("amountSection")

                            // 分类选择
                            CategorySelectionSection(
                                categories: categories,
                                selectedCategory: $selectedCategory
                            )
                            .id("categorySection")

                            // 备注输入
                            BilingualNoteInputSection(
                                note: $note,
                                chineseNote: $chineseNote,
                                englishNote: $englishNote,
                                onChineseNoteTranslated: {
                                    chineseNoteWasTranslated = true
                                },
                                onEnglishNoteTranslated: {
                                    englishNoteWasTranslated = true
                                },
                                onFocusChanged: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("noteSection", anchor: .center)
                                    }
                                }
                            )
                            .environmentObject(translationService)
                            .environmentObject(localizationManager)
                            .onChange(of: chineseNote) { newValue in
                                // 如果用户手动清空了备注，重置翻译状态
                                if newValue.isEmpty {
                                    chineseNoteWasTranslated = false
                                }
                            }
                            .onChange(of: englishNote) { newValue in
                                // 如果用户手动清空了备注，重置翻译状态
                                if newValue.isEmpty {
                                    englishNoteWasTranslated = false
                                }
                            }
                            .id("noteSection")

                            // 日期选择
                            DateSelectionSection(date: $date)
                                .id("dateSection")
                                
                            // 添加底部间距以确保内容不被键盘遮挡
                            Spacer(minLength: 300)
                        }
                        .padding()
                    }
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
            // 只有当选择的分类为空或者类型不匹配时，才设置默认分类
            if selectedCategory == nil || selectedCategory?.type != selectedType {
                selectedCategory = categories.first(where: { $0.type == selectedType })
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
        var isChineseNoteTranslated = chineseNoteWasTranslated
        var isEnglishNoteTranslated = englishNoteWasTranslated
        
        // 如果只有单一语言的备注，不是翻译
        if finalChineseNote != nil && finalEnglishNote == nil {
            isChineseNoteTranslated = false
            isEnglishNoteTranslated = false
        } else if finalEnglishNote != nil && finalChineseNote == nil {
            isEnglishNoteTranslated = false
            isChineseNoteTranslated = false
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