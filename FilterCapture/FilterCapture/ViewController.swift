//
//  ViewController.swift
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

final class ViewController: UIViewController {

  private let captrueView: FilterCaptureView = {
    let captrueView = FilterCaptureView()
    captrueView.configure([
      .filter(CIFilter(name: "")),
      .sessionPreset(.high)
    ])
    return captrueView
  }()

  private let button: UIButton = {
    let button = UIButton()
    button.setTitle("스위치", for: .normal)
    button.addTarget(self, action:#selector(switchTap(sender:)), for: .touchUpInside)
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.view.addSubview(self.captrueView)
    self.view.addSubview(self.button)

    self.makeConstraints()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.captrueView.rx.startCapture.onNext(())
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.captrueView.rx.stopCaptrue.onNext(())
  }

  // MARK: Layout

  private func makeConstraints() {
    self.captrueView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    self.button.snp.makeConstraints { make in
      make.top.equalTo(50)
      make.right.equalTo(-30)
    }
  }

  // MARK: Action

  @objc
  func switchTap(sender: UIButton) {
    self.captrueView.rx.switchCamera.onNext(())
  }

}

