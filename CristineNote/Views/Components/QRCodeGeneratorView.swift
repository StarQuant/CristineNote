import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    let deviceInfo: DeviceInfo
    let onQRGenerated: ((Bool) -> Void)?
    @State private var qrCodeImage: UIImage?
    @State private var isGenerating = true
    @State private var retryCount = 0
    private let maxRetries = 3
    
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
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            if retryCount > 0 {
                                Text("重试中... (\(retryCount)/\(maxRetries))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
            }
            
            // 如果生成失败，显示重试按钮
            if qrCodeImage == nil && !isGenerating && retryCount >= maxRetries {
                Button(action: {
                    retryGenerateQRCode()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新生成")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
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
            print("QRCodeGeneratorView appeared")
            generateQRCode()
        }
        .onDisappear {
            print("QRCodeGeneratorView disappeared")
            // 视图消失时重置状态
            qrCodeImage = nil
            isGenerating = false
            retryCount = 0
        }
    }
    
    private func retryGenerateQRCode() {
        print("Retrying QR code generation")
        retryCount = 0
        qrCodeImage = nil
        generateQRCode()
    }
    
    private func generateQRCode() {
        print("Starting QR code generation, attempt: \(retryCount + 1)")
        isGenerating = true
        
        // 使用主队列确保UI更新
        DispatchQueue.main.async {
            do {
                // 创建二维码数据
                let qrData = QRCodeData(
                    deviceId: deviceInfo.deviceId.uuidString,
                    deviceName: deviceInfo.deviceName,
                    appVersion: deviceInfo.appVersion
                )
                
                let jsonData = try JSONEncoder().encode(qrData)
                let qrString = String(data: jsonData, encoding: .utf8) ?? ""
                print("QR String: \(qrString)")
                
                // 生成二维码图片
                if let generatedImage = generateQRCodeImage(from: qrString) {
                    print("QR code generated successfully")
                    qrCodeImage = generatedImage
                    isGenerating = false
                    onQRGenerated?(true)
                } else {
                    print("Failed to generate QR code image")
                    handleGenerationFailure()
                }
                
            } catch {
                print("Error generating QR code: \(error)")
                handleGenerationFailure()
            }
        }
    }
    
    private func handleGenerationFailure() {
        retryCount += 1
        isGenerating = false
        
        if retryCount < maxRetries {
            // 短暂延迟后重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generateQRCode()
            }
        } else {
            print("Max retries reached for QR code generation")
            onQRGenerated?(false)
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = string.data(using: .utf8) else {
            print("Failed to convert string to data")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // 中等错误纠正级别
        
        guard let outputImage = filter.outputImage else {
            print("Failed to generate CI output image")
            return nil
        }
        
        // 放大图片以提高清晰度
        let scaleX = 250.0 / outputImage.extent.size.width
        let scaleY = 250.0 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgimg = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            print("Failed to create CG image")
            return nil
        }
        
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