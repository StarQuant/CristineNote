import SwiftUI

struct FocusableTextEditor: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    let id: String
    
    init(text: Binding<String>, placeholder: String, id: String = UUID().uuidString) {
        self._text = text
        self.placeholder = placeholder
        self.id = id
    }
    
    var body: some View {
        GeometryReader { geometry in
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
                .overlay(
                    // 占位符文本
                    VStack {
                        HStack {
                            if text.isEmpty {
                                Text(placeholder)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                    .padding(.leading, 16)
                                    .padding(.top, 16)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                )
                .focused($isFocused)
                .onTapGesture {
                    isFocused = true
                }
                .id(id)
        }
        .frame(minHeight: 80)
    }
}

struct NoteInputSection: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("note"))
                .font(.system(.headline, weight: .semibold))

            TextField(LocalizedString("enter_note"), text: $note)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

struct NoteInputWithTranslationSection: View {
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var note: String
    @State private var isTranslating: Bool = false
    @State private var showTranslateCheckmark: Bool = false
    
    // 计算当前系统语言是否为中文
    private var isChineseSystem: Bool {
        localizationManager.currentLanguage.hasPrefix("zh")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("note"))
                .font(.system(.headline, weight: .semibold))

            VStack(spacing: 12) {
                TextField(LocalizedString("enter_note"), text: $note)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                
                HStack {
                    Spacer()
                    Button(action: {
                        translateNote()
                    }) {
                        if isTranslating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if showTranslateCheckmark {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        } else {
                            Text(LocalizedString("translate"))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(note.isEmpty ? .gray : .blue)
                    .disabled(note.isEmpty || isTranslating)
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func translateNote() {
        guard !note.isEmpty else { return }
        
        isTranslating = true
        showTranslateCheckmark = false
        
        Task {
            do {
                let translated: String
                if isChineseSystem {
                    // 中文系统：翻译为英文
                    translated = try await translationService.translateToEnglish(note)
                } else {
                    // 英文或其他系统：翻译为中文
                    translated = try await translationService.translateText(note)
                }
                
                await MainActor.run {
                    // 可以在这里显示翻译结果给用户预览，但不自动替换
                    isTranslating = false
                    showTranslateCheckmark = true
                    
                    // 1.5秒后隐藏勾号
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showTranslateCheckmark = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTranslating = false
                    showTranslateCheckmark = false
                }
            }
        }
    }
}

struct BilingualNoteInputSection: View {
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var note: String
    @Binding var chineseNote: String
    @Binding var englishNote: String
    @State private var isTranslating: Bool = false
    @State private var showTranslateCheckmark: Bool = false
    
    // 计算当前系统语言是否为中文
    private var isChineseSystem: Bool {
        localizationManager.currentLanguage.hasPrefix("zh")
    }
    
    // 根据系统语言确定输入框的占位符和标签
    private var primaryLanguageLabel: String {
        isChineseSystem ? LocalizedString("chinese_note") : LocalizedString("english_note")
    }
    
    private var primaryLanguagePlaceholder: String {
        isChineseSystem ? LocalizedString("enter_chinese_note") : LocalizedString("enter_english_note")
    }
    
    private var secondaryLanguageLabel: String {
        isChineseSystem ? LocalizedString("english_note") : LocalizedString("chinese_note")
    }
    
    private var secondaryLanguagePlaceholder: String {
        isChineseSystem ? LocalizedString("english_translation") : LocalizedString("chinese_translation")
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedString("note"))
                    .font(.system(.headline, weight: .semibold))
                
                // 第一个输入框：系统语言对应的输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryLanguageLabel)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.primary)
                    
                    FocusableTextEditor(
                        text: isChineseSystem ? $chineseNote : $englishNote,
                        placeholder: primaryLanguagePlaceholder,
                        id: "primaryNote"
                    )
                    .id("primaryNote")
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("primaryNote", anchor: .bottom)
                        }
                    }
                }
                
                // 第二个输入框：翻译语言的输入框，带翻译按钮
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(secondaryLanguageLabel)
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.top, 10)
                        
                        Spacer()
                        
                        Button(action: {
                            translateNote()
                        }) {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if showTranslateCheckmark {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            } else {
                                Text(LocalizedString("translate"))
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor((isChineseSystem ? chineseNote.isEmpty : englishNote.isEmpty) ? .gray : .blue)
                        .disabled((isChineseSystem ? chineseNote.isEmpty : englishNote.isEmpty) || isTranslating)
                        .buttonStyle(.plain)
                    }
                    
                    FocusableTextEditor(
                        text: isChineseSystem ? $englishNote : $chineseNote,
                        placeholder: secondaryLanguagePlaceholder,
                        id: "secondaryNote"
                    )
                    .id("secondaryNote")
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("secondaryNote", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private func translateNote() {
        let sourceText = isChineseSystem ? chineseNote : englishNote
        guard !sourceText.isEmpty else { return }
        
        isTranslating = true
        showTranslateCheckmark = false
        
        Task {
            do {
                let translated: String
                if isChineseSystem {
                    // 中文系统：翻译中文到英文
                    translated = try await translationService.translateToEnglish(sourceText)
                } else {
                    // 英文或其他系统：翻译英文到中文
                    translated = try await translationService.translateText(sourceText)
                }
                
                await MainActor.run {
                    if isChineseSystem {
                        englishNote = translated
                    } else {
                        chineseNote = translated
                    }
                    
                    // 更新主要的note字段为当前语言的内容
                    note = sourceText
                    
                    isTranslating = false
                    showTranslateCheckmark = true
                    
                    // 1.5秒后隐藏勾号
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showTranslateCheckmark = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTranslating = false
                    showTranslateCheckmark = false
                }
            }
        }
    }
}