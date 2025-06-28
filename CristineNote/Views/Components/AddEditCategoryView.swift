import SwiftUI

struct AddEditCategoryView: View {
    let type: TransactionType
    let category: TransactionCategory?

    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var primaryLanguageName: String
    @State private var secondaryLanguageName: String
    @State private var iconName: String
    @State private var selectedColor: Color
    @State private var validIcons: [String] = []
    @State private var isTranslating: Bool = false
    @State private var showCheckmark: Bool = false
    
    // 计算当前系统语言是否为中文
    private var isChineseSystem: Bool {
        localizationManager.currentLanguage.hasPrefix("zh")
    }
    
    // 根据系统语言决定输入框的标签
    private var primaryFieldLabel: String {
        isChineseSystem ? LocalizedString("category_name") : LocalizedString("english_name")
    }
    
    private var secondaryFieldLabel: String {
        isChineseSystem ? LocalizedString("english_name") : LocalizedString("category_name")
    }
    
    init(type: TransactionType, category: TransactionCategory?) {
        self.type = type
        self.category = category
        
        // 根据当前系统语言初始化输入框
        if let category = category {
            // 编辑模式
            let isSystemChinese = LocalizationManager.shared.currentLanguage.hasPrefix("zh")
            if isSystemChinese {
                // 系统语言是中文，主要字段是中文名，次要字段是英文名
                self._primaryLanguageName = State(initialValue: category.name)
                self._secondaryLanguageName = State(initialValue: category.englishName ?? "")
            } else {
                // 系统语言是英文或其他，主要字段是英文名，次要字段是中文名
                self._primaryLanguageName = State(initialValue: category.englishName ?? "")
                self._secondaryLanguageName = State(initialValue: category.name)
            }
            self._iconName = State(initialValue: category.iconName)
            self._selectedColor = State(initialValue: category.color)
        } else {
            // 新增模式
            self._primaryLanguageName = State(initialValue: "")
            self._secondaryLanguageName = State(initialValue: "")
            self._iconName = State(initialValue: "circle.fill")
            self._selectedColor = State(initialValue: Color.blue)
        }
    }

    private let allAvailableIcons = [
        // 餐饮相关
        "fork.knife", "cup.and.saucer", "birthday.cake", "wineglass", "cart",
        // 交通相关
        "car.fill", "bus.fill", "bicycle", "airplane", "fuelpump.fill",
        // 购物相关
        "bag.fill", "cart.fill", "creditcard.fill", "giftcard.fill", "storefront",
        // 房屋相关
        "house.fill", "bed.double.fill", "lightbulb.fill", "drop.fill", "bolt.fill",
        // 金融银行
        "building.columns.fill", "banknote.fill", "dollarsign.circle.fill", "percent",
        // 汽车相关
        "wrench.and.screwdriver.fill",
        // 网络支付
        "wifi", "iphone", "globe",
        // 娱乐相关
        "gamecontroller.fill", "tv.fill", "music.note", "film.fill",
        // 健康相关
        "cross.fill", "heart.fill", "figure.walk", "pills.fill",
        // 工作学习
        "book.fill", "graduationcap.fill", "briefcase.fill", "pencil",
        // 其他分类
        "ellipsis.circle.fill", "questionmark.circle.fill", "star.fill", "gift.fill",
        "phone.fill", "envelope.fill", "camera.fill", "location.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(primaryFieldLabel, text: $primaryLanguageName)
                    
                    HStack(spacing: 12) {
                        TextField(secondaryFieldLabel, text: $secondaryLanguageName)
                        
                        Button(action: {
                            translatePrimaryToSecondary()
                        }) {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.blue)
                            } else if showCheckmark {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            } else {
                                Text(LocalizedString("translate"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(primaryLanguageName.isEmpty ? .gray : .blue)
                            }
                        }
                        .disabled(primaryLanguageName.isEmpty || isTranslating)
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section(LocalizedString("icon")) {
                    if validIcons.isEmpty {
                        Text("正在加载图标...")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                            spacing: 12
                        ) {
                            ForEach(validIcons, id: \.self) { icon in
                                Button(action: {
                                    iconName = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(iconName == icon ? .white : .primary)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(iconName == icon ? selectedColor : Color(.systemGray5))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(iconName == icon ? selectedColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }

                Section(LocalizedString("color")) {
                    HStack(spacing: 16) {
                        ForEach([Color.blue, Color.green, Color.red, Color.orange, Color.purple], id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(category == nil ? LocalizedString("add_category") : LocalizedString("edit_category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("save")) {
                        saveCategory()
                    }
                    .disabled(primaryLanguageName.isEmpty)
                }
            }
            .keyboardToolbar()
        }
        .onAppear {
            validateIcons()
        }
    }
    
    // 检查图标是否在当前iOS版本中可用
    private func validateIcons() {
        var validIconsList: [String] = []
        var seenIcons = Set<String>()
        
        for iconName in allAvailableIcons {
            // 检查是否重复
            if seenIcons.contains(iconName) {
                continue // 跳过重复的图标
            }
            seenIcons.insert(iconName)
            
            // 使用简单的UIImage检测，只要能创建就认为可用
            if let _ = UIImage(systemName: iconName) {
                validIconsList.append(iconName)
            }
        }
        
        validIcons = validIconsList
        
        // 确保至少有基本图标
        if validIcons.isEmpty {
            validIcons = ["circle.fill", "star.fill", "heart.fill", "house.fill", "car.fill"]
        }
    }

    private func saveCategory() {
        // 根据系统语言决定如何保存名称
        let chineseName: String
        let englishName: String?
        
        if isChineseSystem {
            // 系统语言是中文，主要字段是中文名，次要字段是英文名
            chineseName = primaryLanguageName
            englishName = secondaryLanguageName.isEmpty ? nil : secondaryLanguageName
        } else {
            // 系统语言是英文或其他，主要字段是英文名，次要字段是中文名
            chineseName = secondaryLanguageName.isEmpty ? primaryLanguageName : secondaryLanguageName
            englishName = primaryLanguageName.isEmpty ? nil : primaryLanguageName
        }
        
        let newCategory = TransactionCategory(
            id: category?.id ?? UUID(),
            name: chineseName,
            englishName: englishName,
            iconName: iconName,
            color: selectedColor,
            type: type
        )

        if let existingCategory = category {
            dataManager.updateCategory(newCategory)
            dataManager.updateTransactionsForEditedCategory(oldCategory: existingCategory, newCategory: newCategory)
        } else {
            dataManager.addCategory(newCategory)
        }

        dismiss()
    }

    // 翻译主要语言到次要语言
    private func translatePrimaryToSecondary() {
        guard !primaryLanguageName.isEmpty else { return }
        
        isTranslating = true
        showCheckmark = false
        
        Task {
            do {
                let translated: String
                if isChineseSystem {
                    // 中文系统：主要字段是中文，翻译为英文
                    translated = try await translationService.translateToEnglish(primaryLanguageName)
                } else {
                    // 英文或其他系统：主要字段是英文，翻译为中文
                    translated = try await translationService.translateText(primaryLanguageName)
                }
                
                await MainActor.run {
                    secondaryLanguageName = translated
                    isTranslating = false
                    showCheckmark = true
                    
                    // 1.5秒后隐藏勾号
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCheckmark = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTranslating = false
                    showCheckmark = false
                }
                // 翻译失败时静默处理，不影响用户体验
            }
        }
    }
}