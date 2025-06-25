import SwiftUI
import UIKit

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingShareSheet = false
    @State private var csvData: Data?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(LocalizedString("export_data"))
                    .font(.title2)

                LocalizedText("export_description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: {
                        exportToCSV()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            LocalizedText("export_csv")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    if dataManager.transactions.isEmpty {
                        Text(LocalizedString("no_data_to_export"))
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text(String(format: LocalizedString("total_transactions"), dataManager.transactions.count))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedString("export_data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let csvData = csvData {
                    ShareSheet(activityItems: [csvData])
                }
            }
        }
    }

    private func exportToCSV() {
        guard !dataManager.transactions.isEmpty else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let headers = [
            LocalizedString("date"),
            LocalizedString("type"),
            LocalizedString("category"),
            LocalizedString("amount"),
            LocalizedString("note")
        ]
        var csvString = headers.joined(separator: ",") + "\n"

        for transaction in dataManager.transactions.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: transaction.date)
            let type = MainActor.assumeIsolated { transaction.type.displayName }
            let category = MainActor.assumeIsolated { transaction.category.displayName(for: dataManager) }
            let amount = String(transaction.amount)
            let note = transaction.note.replacingOccurrences(of: "\"", with: "\"\"")

            csvString += "\(date),\(type),\(category),\(amount),\"\(note)\"\n"
        }

        csvData = csvString.data(using: .utf8)
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}