import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var importResult: ImportResult?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text(LocalizedString("import_data"))
                    .font(.title2)

                LocalizedText("import_description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            LocalizedText("import_csv")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    LocalizedText("import_format_note")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }

                if let result = importResult {
                    ImportResultView(result: result)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedString("import_data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.commaSeparatedText, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(LocalizedString("import_result"), isPresented: $showingAlert) {
                Button(LocalizedString("ok"), role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importCSVFile(from: url)
        case .failure(let error):
            alertMessage = LocalizedString("import_error") + ": \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func importCSVFile(from url: URL) {
        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            let result = parseCSVContent(csvContent)
            importResult = result

            let message = String(format: LocalizedString("import_success_message"),
                                result.successCount,
                                result.duplicateCount,
                                result.errorCount)
            alertMessage = message
            showingAlert = true

        } catch {
            alertMessage = LocalizedString("file_read_error") + ": \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func parseCSVContent(_ content: String) -> ImportResult {
        let lines = content.components(separatedBy: .newlines)
        var successCount = 0
        var duplicateCount = 0
        var errorCount = 0
        var importedTransactions: [Transaction] = []

        // 跳过标题行
        let dataLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        for line in dataLines {
            if let transaction = parseCSVLine(line) {
                // 检查是否重复
                if !isDuplicateTransaction(transaction) {
                    importedTransactions.append(transaction)
                    successCount += 1
                } else {
                    duplicateCount += 1
                }
            } else {
                errorCount += 1
            }
        }

        // 批量添加交易
        for transaction in importedTransactions {
            dataManager.addTransaction(transaction)
        }

        return ImportResult(
            successCount: successCount,
            duplicateCount: duplicateCount,
            errorCount: errorCount
        )
    }

    private func parseCSVLine(_ line: String) -> Transaction? {
        let columns = parseCSVColumns(line)
        guard columns.count >= 5 else { return nil }

        // 解析日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = dateFormatter.date(from: columns[0]) else { return nil }

        // 解析类型
        let typeString = columns[1]
        guard let type = TransactionType.allCases.first(where: { currentType in
            let displayName = MainActor.assumeIsolated { currentType.displayName }
            return displayName == typeString || currentType.rawValue == typeString
        }) else { return nil }

        // 解析分类
        let categoryName = columns[2]
        let categories = type == .expense ? dataManager.expenseCategories : dataManager.incomeCategories
        guard let category = categories.first(where: { currentCategory in
            let displayName = MainActor.assumeIsolated { currentCategory.displayName(for: dataManager) }
            return displayName == categoryName || currentCategory.name == categoryName
        }) else { return nil }

        // 解析金额
        guard let amount = Double(columns[3]), amount > 0 else { return nil }

        // 备注
        let note = columns.count > 4 ? columns[4].trimmingCharacters(in: CharacterSet(charactersIn: "\"")) : ""

        // 导入的交易使用当前系统货币
        return Transaction(amount: amount, currency: dataManager.currentSystemCurrency, type: type, category: category, note: note, date: date)
    }

    private func parseCSVColumns(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }

            i = line.index(after: i)
        }

        columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
        return columns
    }

    private func isDuplicateTransaction(_ transaction: Transaction) -> Bool {
        return dataManager.transactions.contains { existing in
            abs(existing.date.timeIntervalSince(transaction.date)) < 60 && // 1分钟内
            existing.originalAmount == transaction.originalAmount &&
            existing.originalCurrency == transaction.originalCurrency &&
            existing.type == transaction.type &&
            existing.category.id == transaction.category.id &&
            existing.note == transaction.note
        }
    }
}

struct ImportResult {
    let successCount: Int
    let duplicateCount: Int
    let errorCount: Int
}

struct ImportResultView: View {
    let result: ImportResult

    var body: some View {
        VStack(spacing: 8) {
            LocalizedText("import_result")
                .font(.headline)

            HStack(spacing: 20) {
                VStack {
                    Text("\(result.successCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    LocalizedText("imported")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(result.duplicateCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    LocalizedText("duplicated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(result.errorCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    LocalizedText("errors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
