import SwiftUI

struct ExchangeRateView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingManualInput = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessIcon = false
    
    var exchangeRateService: ExchangeRateService {
        dataManager.exchangeRateService
    }
    
    var body: some View {
        NavigationView {
            List {
                // 更新状态
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedString("last_updated"))
                                .font(.subheadline)
                            
                            if let updateTime = exchangeRateService.lastUpdateTime {
                                Text(updateTime, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(LocalizedString("never_updated"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        Task {
                            do {
                                try await exchangeRateService.fetchRatesFromAPI()
                                await MainActor.run {
                                    // 显示成功图标动画
                                    showSuccessIcon = true
                                    // 2秒后隐藏成功图标
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showSuccessIcon = false
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = error.localizedDescription
                                    showingErrorAlert = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            if exchangeRateService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 24)
                            } else if showSuccessIcon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                    .scaleEffect(showSuccessIcon ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: showSuccessIcon)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                            }
                            
                            Text(showSuccessIcon ? LocalizedString("update_success") : LocalizedString("update_from_api"))
                                .foregroundColor(exchangeRateService.isLoading ? .secondary : .primary)
                                .animation(.easeInOut(duration: 0.3), value: showSuccessIcon)
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(exchangeRateService.isLoading)
                }
                
                // 当前汇率显示
                Section(LocalizedString("exchange_rates")) {
                    ForEach(Currency.allCases, id: \.self) { fromCurrency in
                        ForEach(Currency.allCases, id: \.self) { toCurrency in
                            if fromCurrency != toCurrency {
                                RateRowView(from: fromCurrency, to: toCurrency)
                                    .environmentObject(dataManager)
                                    .id("\(fromCurrency.apiCode)-\(toCurrency.apiCode)-\(exchangeRateService.rates.hashValue)")
                            }
                        }
                    }
                }
                
                // 手动设置
                Section {
                    Button(action: {
                        showingManualInput = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text(LocalizedString("set_manual_rate"))
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(LocalizedString("exchange_rates"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualInput) {
                ManualRateInputView()
                    .environmentObject(dataManager)
            }
            .alert(LocalizedString("update_failed"), isPresented: $showingErrorAlert) {
                Button(LocalizedString("ok")) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct RateRowView: View {
    let from: Currency
    let to: Currency
    @EnvironmentObject var dataManager: DataManager
    
    var exchangeRateService: ExchangeRateService {
        dataManager.exchangeRateService
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text("1")
                Text(from.apiCode)
                Text("=")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Spacer()
            
            if let rate = exchangeRateService.getRate(from: from, to: to) {
                HStack(spacing: 2) {
                    Text(String(format: "%.4f", rate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(to.apiCode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("--")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ManualRateInputView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var fromCurrency: Currency = .cny
    @State private var toCurrency: Currency = .php
    @State private var rateValue = ""
    
    var exchangeRateService: ExchangeRateService {
        dataManager.exchangeRateService
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(LocalizedString("from_currency"), selection: $fromCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.apiCode)
                                .tag(currency)
                        }
                    }
                    
                    Picker(LocalizedString("to_currency"), selection: $toCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.apiCode)
                                .tag(currency)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text(LocalizedString("rate_value"))
                        TextField(LocalizedString("enter_rate"), text: $rateValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text(LocalizedString("rate_example"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedString("set_manual_rate"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("save")) {
                        saveRate()
                    }
                    .disabled(!isFormValid)
                }
            }
            .keyboardToolbar()
        }
        .onAppear {
            // 预填充当前汇率值
            if let currentRate = exchangeRateService.getRate(from: fromCurrency, to: toCurrency) {
                rateValue = String(format: "%.4f", currentRate)
            }
        }
        .onChange(of: fromCurrency) { _ in updateRateValue() }
        .onChange(of: toCurrency) { _ in updateRateValue() }
    }
    
    private var isFormValid: Bool {
        fromCurrency != toCurrency && 
        !rateValue.isEmpty &&
        Double(rateValue) != nil &&
        Double(rateValue)! > 0
    }
    
    private func updateRateValue() {
        if let currentRate = exchangeRateService.getRate(from: fromCurrency, to: toCurrency) {
            rateValue = String(format: "%.4f", currentRate)
        } else {
            rateValue = ""
        }
    }
    
    private func saveRate() {
        guard let rate = Double(rateValue), rate > 0 else { return }
        
        Task {
            await exchangeRateService.setManualRate(from: fromCurrency, to: toCurrency, rate: rate)
            await MainActor.run {
                dismiss()
            }
        }
    }
} 