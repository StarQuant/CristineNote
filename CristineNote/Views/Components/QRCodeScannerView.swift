import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Binding var isPresented: Bool
    let onQRCodeDetected: (QRCodeData) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 相机预览
                CameraPreview(onQRCodeDetected: onQRCodeDetected)
                    .ignoresSafeArea()
                
                // 扫描框叠加层
                ScannerOverlay()
                
                // 顶部指导文字
                VStack {
                    Text(LocalizedString("scan_qr_code"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
            .navigationBarHidden(true)
            .overlay(
                // 关闭按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding()
                    }
                    Spacer()
                }
            )
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let onQRCodeDetected: (QRCodeData) -> Void
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRCodeScannerDelegate {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        func didDetectQRCode(_ qrCodeData: QRCodeData) {
            parent.onQRCodeDetected(qrCodeData)
        }
    }
}

protocol QRCodeScannerDelegate: AnyObject {
    func didDetectQRCode(_ qrCodeData: QRCodeData)
}

class CameraPreviewUIView: UIView {
    weak var delegate: QRCodeScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastDetectionTime: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                failed()
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                failed()
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = bounds
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                layer.addSublayer(previewLayer)
            }
            
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
            
        } catch {
            failed()
        }
    }
    
    private func failed() {
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
}

extension CameraPreviewUIView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // 防止重复扫描
        let now = Date()
        if now.timeIntervalSince(lastDetectionTime) < 2.0 {
            return
        }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // 解析二维码数据
            if let qrCodeData = parseQRCode(stringValue) {
                lastDetectionTime = now
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                DispatchQueue.main.async {
                    self.delegate?.didDetectQRCode(qrCodeData)
                }
            }
        }
    }
    
    private func parseQRCode(_ string: String) -> QRCodeData? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        do {
            let qrCodeData = try JSONDecoder().decode(QRCodeData.self, from: data)
            return qrCodeData
        } catch {
            return nil
        }
    }
}

struct ScannerOverlay: View {
    var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // 扫描框
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 250, height: 250)
                .background(Color.clear)
            
            // 扫描线动画
            ScanningLine()
                .frame(width: 250, height: 250)
                .clipped()
        }
    }
}

struct ScanningLine: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.green)
                .frame(height: 2)
                .offset(y: isAnimating ? 125 : -125)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
} 