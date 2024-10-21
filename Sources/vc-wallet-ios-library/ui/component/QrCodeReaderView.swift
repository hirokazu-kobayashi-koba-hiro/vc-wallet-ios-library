//
//  QrCodeReaderView.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/21.
//
import SwiftUI
import VisionKit

public struct QrCodeReaderView: UIViewControllerRepresentable {

  private let onRecognized: (String?) -> Void

  public init(onRecognized: @escaping (String?) -> Void) {
    self.onRecognized = onRecognized
  }

  public func makeUIViewController(context: Self.Context) -> some UIViewController {

    let viewController = DataScannerViewController(
      recognizedDataTypes: [
        .barcode(symbologies: [.qr])
      ],
      qualityLevel: .fast,
      recognizesMultipleItems: false,
      isHighFrameRateTrackingEnabled: false,
      isHighlightingEnabled: true)

    viewController.delegate = context.coordinator

    DispatchQueue.main.async {
      try? viewController.startScanning()
    }
    return viewController
  }

  public func updateUIViewController(
    _ uiViewController: Self.UIViewControllerType, context: Self.Context
  ) {

  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public class Coordinator: NSObject, DataScannerViewControllerDelegate {

    let parent: QrCodeReaderView

    fileprivate init(parent: QrCodeReaderView) {
      self.parent = parent
    }

    public func dataScanner(
      _ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
      allItems: [RecognizedItem]
    ) {
      guard let item = addedItems.first else {
        return
      }
      Logger.shared.debug("QrCodeReaderView: \(item)")
      switch item {
      case .barcode(let item):
        guard let qrCodeValue = item.payloadStringValue else {
          break
        }
        parent.onRecognized(qrCodeValue)
        break
      default:
        break
      }
    }
  }
}
