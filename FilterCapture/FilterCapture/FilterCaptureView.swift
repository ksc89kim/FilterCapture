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

  // MARK: - Defines

  enum Configuration {
    case filter(CIFilter?)
    case sessionPreset(AVCaptureSession.Preset)
  }

  enum QueueName {
    static let video = "com.tronplay.videoQueue"
  }


  // MARK: - UI Components

  private let preImageView: UIImageView = {
    let preview = UIImageView()
    return preview
  }()


  // MARK: - Properties

  private var isCemeraFront: Bool = false

  var didMakeConstraints: Bool = false

  private var videoDevice: AVCaptureDevice? {
    let position: AVCaptureDevice.Position = (self.isCemeraFront) ? .front:.back
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
    let filter = CIFilter.clear
    return filter
  }()

  private let context: CIContext =  {
    let context = CIContext()
    return context
  }()


  // MARK: - Initializers

  init() {
    super.init(frame: .zero)

    self.makeLayout()
    self.updateCameraSession()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }


  // MARK: - Configure

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


  // MARK: - Cameara Session

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

      self.cameraSession.beginConfiguration()

      if let firstInput = self.cameraSession.inputs.first {
        self.cameraSession.removeInput(firstInput)
      }

      if self.cameraSession.canAddInput(deviceInput) {
        self.cameraSession.addInput(deviceInput)
      }

      if let firstOutput = self.cameraSession.outputs.first {
        self.cameraSession.removeOutput(firstOutput)
      }

      if self.cameraSession.canAddOutput(dataOutput) {
        self.cameraSession.addOutput(dataOutput)
      }

      dataOutput.connection(with: .video)?.videoOrientation = .portrait

      self.cameraSession.commitConfiguration()

      let queue = DispatchQueue(label: QueueName.video, attributes: [])
      dataOutput.setSampleBufferDelegate(self, queue: queue)

    } catch let error as NSError {
      print("\(error), \(error.localizedDescription)")
    }
  }

  
  // MARK: - ETC

  fileprivate func switchCamera() {
    self.cameraSession.stopRunning()
    self.isCemeraFront.toggle()
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


extension FilterCaptureView: MakeLayout {
  func addSubViews() {
    self.addSubview(self.preImageView)
  }

  func makeConstraints() {
    self.preImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}


extension FilterCaptureView: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    let convertImage = self.convertSmapleBuffer(sampleBuffer: sampleBuffer)
    DispatchQueue.main.async { [weak self] in
      self?.preImageView.image = convertImage
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

