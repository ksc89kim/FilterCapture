//
//  FilterCaptureView.swift
//  FilterCapture
//
//  Created by sc.kim on 2020/07/18.
//  Copyright © 2020 sc.kim. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import SnapKit

final class FilterCaptureView: UIView {

  enum Configuration {
    case filter(CIFilter?)
    case sessionPreset(AVCaptureSession.Preset)
  }


  // MARK: UI components

  private let preImageView: UIImageView = {
    let preview = UIImageView()
    return preview
  }()


  // MARK: Properties

  private var isCemeraFront: Bool = false

  private var videoDevice: AVCaptureDevice? {
    let position: AVCaptureDevice.Position = (isCemeraFront) ? .front:.back
    let device = AVCaptureDevice.default(
      .builtInWideAngleCamera,
      for: .video,
      position: position
    )
    return device
  }

  fileprivate var cameraSession: AVCaptureSession = {
    let session = AVCaptureSession()
    session.sessionPreset = .high
    return session
  }()

  private var filter: CIFilter? = {
    let filter = CIFilter(name: "CISepiaTone")
    return filter
  }()

  private let context: CIContext =  {
    let context = CIContext()
    return context
  }()


  // MARK: Initializer

  init() {
    super.init(frame: .zero)

    self.addSubview(preImageView)
    self.updateCameraSession()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }


  // MARK: Layout

  private(set) var setupMakeConstraints = false

  override func updateConstraints() {
    if !self.setupMakeConstraints {
      self.makeConstraints()
      self.setupMakeConstraints = true
    }
    super.updateConstraints()
  }

  private func makeConstraints() {
    self.preImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }


  // MARK: Configure

  func configure(_ configurations: [Configuration]) {
    DispatchQueue.main.async { [weak self] in
      configurations.forEach { [weak self] config in
        switch config {
        case .filter(let filter):
          self?.filter = filter
          break
        case .sessionPreset(let preset):
          self?.cameraSession.sessionPreset = preset
          break
        }
      }
    }
  }


  // MARK: Cameara Session

  private func updateCameraSession() {
    do {
      guard let device = self.videoDevice else {
        return
      }

      let deviceInput = try AVCaptureDeviceInput(device: device)

      let dataOutput = AVCaptureVideoDataOutput()
      dataOutput.videoSettings = [
        (kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)
      ]

      cameraSession.beginConfiguration()

      if let firstInput = cameraSession.inputs.first {
        cameraSession.removeInput(firstInput)
      }

      if cameraSession.canAddInput(deviceInput) {
        cameraSession.addInput(deviceInput)
      }

      if let firstOutput = cameraSession.outputs.first {
        cameraSession.removeOutput(firstOutput)
      }

      if cameraSession.canAddOutput(dataOutput) {
        cameraSession.addOutput(dataOutput)
      }

      dataOutput.connection(with: .video)?.videoOrientation = .portrait

      cameraSession.commitConfiguration()

      let queue = DispatchQueue(label: "com.tronplay.videoQueue", attributes: [])
      dataOutput.setSampleBufferDelegate(self, queue: queue)

    } catch let error as NSError {
      print("\(error), \(error.localizedDescription)")
    }
  }

  
  // MARK: ETC

  fileprivate func switchCamera() {
    self.cameraSession.stopRunning()
    isCemeraFront.toggle()
    self.updateCameraSession()
    self.cameraSession.startRunning()
  }

  private func convertSmapleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
    guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return nil
    }

    let cameraImage = CIImage(cvImageBuffer: videoPixelBuffer)

    guard let filter = self.filter else {
      return UIImage(ciImage: cameraImage)
    }

    filter.setValue(cameraImage, forKey: kCIInputImageKey)

    guard let outputImage = filter.outputImage else {
      return nil
    }

    guard let cgImage = self.context.createCGImage(
      outputImage,
      from: cameraImage.extent
      ) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
  }
}


extension FilterCaptureView: AVCaptureVideoDataOutputSampleBufferDelegate {

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    let convertImage = self.convertSmapleBuffer(sampleBuffer: sampleBuffer)
    DispatchQueue.main.async {
      self.preImageView.image = convertImage
    }
  }
  
}

extension Reactive where Base: FilterCaptureView {
  var switchCamera: Binder<Void> {
    return Binder(self.base) { view, _ in
      view.switchCamera()
    }
  }

  var startCapture: Binder<Void> {
    return Binder(self.base) { view, _ in
        view.cameraSession.startRunning()
    }
  }

  var stopCaptrue: Binder<Void> {
    return Binder(self.base) { view, _ in
        view.cameraSession.stopRunning()
    }
  }
}

