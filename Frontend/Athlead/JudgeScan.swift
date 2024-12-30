import SwiftUI
import AVFoundation

struct JudgeScanView: View {
    @StateObject private var scannerViewModel = QRCodeScannerViewModel()

    var body: some View {
        VStack {
            if scannerViewModel.isScanning {
                CameraPreview(session: scannerViewModel.captureSession)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("QR Code Scanner")
                    .font(.largeTitle)
                    .padding()
            }

            Button(action: {
                scannerViewModel.toggleScanning()
            }) {
                Text(scannerViewModel.isScanning ? "Stop Scanning" : "Start Scan")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(scannerViewModel.isScanning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
}

class QRCodeScannerViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scannedCode: String? = nil

    let captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera available.")
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            print("Failed to create video input.")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Unable to add video input to session.")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("Unable to add metadata output to session.")
            return
        }
    }

    func toggleScanning() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }

    private func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            DispatchQueue.main.async {
                self.isScanning = true
            }
        }
    }

    private func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            DispatchQueue.main.async {
                self.isScanning = false
            }
        }
    }
}

extension QRCodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let scannedValue = metadataObject.stringValue else {
            return
        }
        scannedCode = scannedValue
        print("Scanned QR Code: \(scannedValue)")
        
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        context.coordinator.setupPreviewLayer(for: view, session: session)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = context.coordinator.previewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?

        func setupPreviewLayer(for view: UIView, session: AVCaptureSession) {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.main.async {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
                self.previewLayer = previewLayer
            }
        }
    }
}


