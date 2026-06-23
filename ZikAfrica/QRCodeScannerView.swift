//
//  QRCodeScannerView.swift
//  ZikAfrica
//
//  Created by Valérien YEHOUENOU on 09/06/2026.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {

    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {

        let controller = ScannerViewController()

        controller.onCodeScanned = onCodeScanned

        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onCodeScanned("ZA-0001")
        }
        #endif

        return controller
    }
    
    func updateUIViewController(
        _ uiViewController: ScannerViewController,
        context: Context
    ) {}
}

class ScannerViewController:
    UIViewController,
    AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?
    private var hasReportedCode = false

    override func viewDidLoad() {

        super.viewDidLoad()

        captureSession = AVCaptureSession()

        guard let videoCaptureDevice =
                AVCaptureDevice.default(for: .video)
        else { return }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput =
                try AVCaptureDeviceInput(
                    device: videoCaptureDevice
                )
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {

            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(
                self,
                queue: DispatchQueue.main
            )

            metadataOutput.metadataObjectTypes = [
                .qr
            ]
        }

        previewLayer =
            AVCaptureVideoPreviewLayer(
                session: captureSession
            )

        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {

        guard !hasReportedCode,
              let metadataObject =
                metadataObjects.first
                as? AVMetadataMachineReadableCodeObject,
              let stringValue =
                metadataObject.stringValue
        else {
            return
        }

        hasReportedCode = true
        captureSession.stopRunning()

        onCodeScanned?(stringValue)
    }
}
