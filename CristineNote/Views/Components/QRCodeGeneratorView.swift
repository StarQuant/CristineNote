import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    let deviceInfo: DeviceInfo
    let onQRGenerated: ((Bool) -> Void)?
    @State private var qrCodeImage: UIImage?
    
    init(deviceInfo: DeviceInfo, onQRGenerated: ((Bool) -> Void)? = nil) {
        self.deviceInfo = deviceInfo
        self.onQRGenerated = onQRGenerated
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "qrcode")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                LocalizedText("waiting_connection")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                LocalizedText("scan_qr_instruction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 二维码
            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(width: 250, height: 250)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
            
            // 设备信息
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(.blue)
                    LocalizedText("device_name")
                        .fontWeight(.medium)
                    Spacer()
                    Text(deviceInfo.deviceName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    LocalizedText("app_version")
                        .fontWeight(.medium)
                    Spacer()
                    Text(deviceInfo.appVersion)
                        .foregroundColor(.secondary)
                }
                
                if let lastSync = deviceInfo.lastSyncTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        LocalizedText("last_sync")
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatDate(lastSync))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
        }
        .padding()
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        do {
            // 创建二维码数据
            let qrData = QRCodeData(
                deviceId: deviceInfo.deviceId.uuidString,
                deviceName: deviceInfo.deviceName,
                appVersion: deviceInfo.appVersion
            )
            
            let jsonData = try JSONEncoder().encode(qrData)
            let qrString = String(data: jsonData, encoding: .utf8) ?? ""
            
            // 生成二维码图片
            qrCodeImage = generateQRCodeImage(from: qrString)
            
            // 通知二维码生成完成
            onQRGenerated?(qrCodeImage != nil)
            
        } catch {
            // 生成失败也要通知
            onQRGenerated?(false)
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // 中等错误纠正级别
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // 放大图片以提高清晰度
        let scaleX = 250.0 / outputImage.extent.size.width
        let scaleY = 250.0 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgimg = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        return UIImage(cgImage: cgimg)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "zh-Hans" ? "zh_CN" : "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - 二维码数据结构
struct QRCodeData: Codable {
    let deviceId: String
    let deviceName: String
    let appVersion: String
} 