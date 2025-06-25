import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var dataManager: DataManager
    @State private var apiKey = ""
    @State private var showingApiKeyAlert = false
    @State private var showingExportSheet = false
    @State private var showingAbout = false
    @State private var showingLanguageSelection = false
    @State private var showingImportSheet = false
    @State private var showingDataSync = false

    var body: some View {
        List {
            // AI翻译设置
            Section(LocalizedString("ai_translation")) {
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("openai_api_key"))
                            .font(.subheadline)

                        if let key = translationService.getAPIKey(), !key.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(LocalizedString("configured"))
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text(LocalizedString("openai_translation_enabled"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(LocalizedString("basic_translation_available"))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(LocalizedString("set_api_for_better_translation"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Button(LocalizedString("set")) {
                        showingApiKeyAlert = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }

            // 数据管理
            Section(LocalizedString("data_management")) {
                Button(action: {
                    showingDataSync = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Text(LocalizedString("device_sync"))
                    }
                    .padding(.vertical, 4)
                }

                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text(LocalizedString("export_data"))
                    }
                    .padding(.vertical, 4)
                }

                Button(action: {
                    showingImportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)

                        Text(LocalizedString("import_data"))
                    }
                    .padding(.vertical, 4)
                }
            }

            // 应用设置
            Section(LocalizedString("app_settings")) {
                Button(action: {
                    showingLanguageSelection = true
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedString("language"))

                            LocalizedText(dataManager.currentLanguage == "zh-Hans" ? "chinese" : "english")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            // 关于
            Section(LocalizedString("about")) {
                Button(action: {
                    showingAbout = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CristineNote")

                            Text(LocalizedString("version"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            apiKey = translationService.getAPIKey() ?? ""
        }
        .alert(LocalizedString("set_openai_api_key"), isPresented: $showingApiKeyAlert) {
            TextField(LocalizedString("enter_api_key"), text: $apiKey)
                .textContentType(.password)

            Button(LocalizedString("cancel"), role: .cancel) { }

            Button(LocalizedString("save")) {
                translationService.setAPIKey(apiKey)
            }
        } message: {
            Text(LocalizedString("enter_openai_api_key_message"))
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingDataSync) {
            DataSyncView(dataManager: dataManager)
                .environmentObject(dataManager)
        }
    }
}