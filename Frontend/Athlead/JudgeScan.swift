import AVFoundation
import UIKit
import SwiftUI

struct JudgeScanView : View {
    @State private var scannedCode: String? = ""
    @State private var scannedAParticipant = false
    var body: some View {
        VStack {
            if (scannedAParticipant){
                Text("Participant").foregroundColor(Color.green)
            } else {
                Text("Not a participant").foregroundColor(Color.red)
            }
            
            ScanButton(scannedCode: $scannedCode)
        }.onChange(of: scannedCode){
            let split = scannedCode?.split(separator: ";");
            if split == nil { print("Scanned value was invalid - nil")}
            let unwrappedSplit = split.unsafelyUnwrapped;
            if unwrappedSplit.count != 2 { print("Scanned value was invalid - unexpected format") }
            let contest_id = unwrappedSplit.first.unsafelyUnwrapped;
            let user_id = unwrappedSplit.last.unsafelyUnwrapped;
            print("Contest id: ", contest_id)
            print("User id: ", user_id)
            
            fetch("\(apiURL)/contests/\(contest_id)/participants/\(user_id)", IsParticipantCheckResponse.self){
                response in
                switch response {
                case .success(let res): scannedAParticipant = res.is_participant; print(res)
                case .failure(let err): print(err)
                }
            }
        }
        
    }
}

struct ScanButton: View {
    @State private var showsScanner = false
    
    @State private var showsMissingCameraAccessAlert = false
    
    @Binding var scannedCode: String?
    
    var body: some View {
        Button(action: {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                if granted {
                    showsScanner = true
                } else {
                    showsMissingCameraAccessAlert = true
                }
            })
        }, label: {
            VStack {
                Image(systemName: "qrcode.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                Text("Scannen")
                    .font(.title)
            }
        })
        .alert("Die App benötigt für das Scannen des QR-Codes Zugriff auf die Kamera", isPresented: $showsMissingCameraAccessAlert, actions: {
            openSettingsButton
            dismissMissingCameraAccessAlertButton
        }, message: {
            Text("Bitte erlauben Sie den Zugriff auf die Kamera in den Einstellungen.")
        })
        .sheet(isPresented: $showsScanner) {
            QRCodeScannerView(scannedCode: $scannedCode)
        }
    }
    
    private var openSettingsButton: some View {
        Button("Einstellungen öffnen") {
            showsMissingCameraAccessAlert = false
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
    
    private var dismissMissingCameraAccessAlertButton: some View {
        Button("Abbrechen", role: .cancel) {
            showsMissingCameraAccessAlert = false
        }
    }
}

struct QRCodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let qrCodeScannerViewController = QRCodeScannerViewController()
        qrCodeScannerViewController.delegate = context.coordinator
        return qrCodeScannerViewController
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
    
    class Coordinator: NSObject, QRCodeScannerViewControllerDelegate {
        var parent: QRCodeScannerView
        
        init(_ qrCodeScannerView: QRCodeScannerView) {
            parent = qrCodeScannerView
        }
        
        func qrCodeScannerViewControllerDidScanCode(_ code: String) {
            parent.scannedCode = code
        }
    }
}

class QRCodeScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var delegate: QRCodeScannerViewControllerDelegate!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            captureSession = nil
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            captureSession = nil
            return
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func found(code: String) {
        delegate.qrCodeScannerViewControllerDidScanCode(code)
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        dismiss(animated: true)
    }
}

protocol QRCodeScannerViewControllerDelegate {
    func qrCodeScannerViewControllerDidScanCode(_ code: String)
}
