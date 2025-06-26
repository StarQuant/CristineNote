import SwiftUI

struct CurrencySelector: View {
    @Binding var selectedCurrency: Currency
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        Menu {
            ForEach(Currency.allCases, id: \.self) { currency in
                Button(action: {
                    selectedCurrency = currency
                }) {
                    HStack {
                        Text(currency.symbol)
                        Text(currency.displayName)
                        
                        if currency == selectedCurrency {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCurrency.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
            )
        }
    }
} 