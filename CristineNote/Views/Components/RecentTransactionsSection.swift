import SwiftUI

struct RecentTransactionsSection: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var localizationManager: LocalizationManager

    var recentTransactions: [Transaction] {
        Array(dataManager.transactions.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedString("recent_transactions"))
                    .font(.system(.headline, weight: .semibold))

                Spacer()

                NavigationLink(destination: TransactionListView().environmentObject(dataManager).environmentObject(translationService).environmentObject(localizationManager)) {
                    Text(LocalizedString("view_all"))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text(LocalizedString("no_transactions"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(LocalizedString("add_first_transaction"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .environmentObject(localizationManager)
                    }
                }
            }
        }
    }
}