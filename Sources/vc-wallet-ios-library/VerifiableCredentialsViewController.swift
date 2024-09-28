//
//  VerifiableCredentialsViewController.swift
//
//
//  Created by 小林弘和 on 2024/09/26.
//

import SwiftUI
import UIKit
import AVFoundation

class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()

        // Set up the camera as an input device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Your device does not support video capture.")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Unable to initialize video input")
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("Could not add video input to capture session.")
            return
        }

        // Set up metadata output for detecting QR codes
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr] // Define the metadata types to detect (QR code)
        } else {
            print("Could not add metadata output.")
            return
        }

        // Display camera feed in a preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Start the session
        captureSession.startRunning()
    }

    // This method is called whenever a QR code is detected
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate)) // Optional: vibrate on detection
            found(code: stringValue)
        }
    }

    func found(code: String) {
        print("QR Code detected: \(code)")
        // Handle the QR code (e.g., display it, navigate to a URL, etc.)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    // Clean up the session when the view controller is dismissed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
}

struct VerifiableCredentialsView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    VerifiableCredentialsView()
}
