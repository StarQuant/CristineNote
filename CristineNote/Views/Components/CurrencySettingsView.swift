import SwiftUI

struct CurrencySettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(currency.symbol)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                    
                                    Text(currency.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text(currency.apiCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if dataManager.currentSystemCurrency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dataManager.setSystemCurrency(currency)
                        }
                    }
                } header: {
                    Text(LocalizedString("select_language"))
                        .textCase(.none)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("切换系统货币后，所有金额显示将按照新的货币和当前汇率进行转换。")
                        Text("您的原始交易数据不会改变，仅显示方式会更新。")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedString("system_currency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
} 