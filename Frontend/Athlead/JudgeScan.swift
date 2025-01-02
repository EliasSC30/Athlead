import SwiftUI
import AVFoundation

struct JudgeScanView: View {
    @StateObject private var scannerViewModel = QRCodeScannerViewModel()

    var body: some View {
        ZStack {
            if scannerViewModel.isScanning {
                CameraPreview(session: scannerViewModel.captureSession)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("QR Code Scanner")
                    .padding()
                    .bold()
            }

            VStack {
                Spacer()

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
                .padding(.bottom)
            }
        }
        .onAppear {
            scannerViewModel.configureSession()
        }
    }
}


class QRCodeScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedCode: String? = nil

    let captureSession = AVCaptureSession()

    func configureSession() {
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

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let scannedValue = metadataObject.stringValue else {
            return
        }

        // Handle the scanned value on the background thread
            DispatchQueue.global(qos: .userInitiated).async {
                // Process scanned value here if needed
                DispatchQueue.main.async {
                    self.scannedCode = scannedValue
                    print("Scanned QR Code: \(scannedValue)")
                }
            }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}





