import SwiftUI

struct AddEditCategoryView: View {
    let type: TransactionType
    let category: TransactionCategory?

    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var englishName: String
    @State private var iconName: String
    @State private var selectedColor: Color
    @State private var nameDebounceTimer: Timer?
    @State private var englishNameDebounceTimer: Timer?
    @State private var validIcons: [String] = []
    
    init(type: TransactionType, category: TransactionCategory?) {
        self.type = type
        self.category = category
        
        // 直接在init中初始化State变量
        if let category = category {
            self._name = State(initialValue: category.name)
            self._englishName = State(initialValue: category.englishName ?? "")
            self._iconName = State(initialValue: category.iconName)
            self._selectedColor = State(initialValue: category.color)
        } else {
            self._name = State(initialValue: "")
            self._englishName = State(initialValue: "")
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
                    TextField(LocalizedString("category_name"), text: $name)
                        .onChange(of: name) { newValue in
                            // 防抖动翻译
                            nameDebounceTimer?.invalidate()
                            nameDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                if !newValue.isEmpty && englishName.isEmpty {
                                    translateToEnglish(newValue)
                                }
                            }
                        }

                    TextField(LocalizedString("english_name"), text: $englishName)
                        .onChange(of: englishName) { newValue in
                            // 防抖动翻译
                            englishNameDebounceTimer?.invalidate()
                            englishNameDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                if !newValue.isEmpty && name.isEmpty {
                                    translateToChinese(newValue)
                                }
                            }
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
                    .disabled(name.isEmpty)
                }
            }
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
        let newCategory = TransactionCategory(
            id: category?.id ?? UUID(),
            name: name,
            englishName: englishName.isEmpty ? nil : englishName,
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

    // 翻译中文到英文
    private func translateToEnglish(_ text: String) {
        Task {
            do {
                let translated = try await translationService.translateToEnglish(text)
                await MainActor.run {
                    englishName = translated
                }
            } catch {
                // 翻译失败时静默处理，不影响用户体验
            }
        }
    }

    // 翻译英文到中文
    private func translateToChinese(_ text: String) {
        Task {
            do {
                let translated = try await translationService.translateText(text)
                await MainActor.run {
                    name = translated
                }
            } catch {
                // 翻译失败时静默处理，不影响用户体验
            }
        }
    }
}