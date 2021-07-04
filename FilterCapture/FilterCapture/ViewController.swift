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

  // MARK: - Defines

  enum Text {
    static let buttonTitle = "스위치"
  }


  // MARK: - UI Components

  private let captrueView: FilterCaptureView = {
    let captrueView = FilterCaptureView()
    captrueView.configure([
      .filter(.sepiaTone),
      .sessionPreset(.high)
    ])
    return captrueView
  }()

  private let switchButton: UIButton = {
    let button = UIButton()
    button.setTitle(Text.buttonTitle, for: .normal)
    return button
  }()


  // MARK: - Properties

  let disposeBag: DisposeBag = DisposeBag()

  var didMakeConstraints: Bool = false


  // MARK: - Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    self.makeLayout()
    self.bind()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.captrueView.rx.startCapture.onNext(())
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.captrueView.rx.stopCaptrue.onNext(())
  }


  // MARK: - Bind

  func bind() {
    self.switchButton.rx.tap
      .bind(to: self.captrueView.rx.switchCamera)
      .disposed(by: self.disposeBag)
  }
}


extension ViewController: MakeLayout {
  enum Metric {
    static let switchButtonTop = 50
    static let switchButtonRight = -30
  }

  func addSubViews() {
    self.view.addSubview(self.captrueView)
    self.view.addSubview(self.switchButton)
  }

  func makeConstraints() {
    self.captrueView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    self.switchButton.snp.makeConstraints { make in
      make.top.equalTo(Metric.switchButtonTop)
      make.right.equalTo(Metric.switchButtonRight)
    }
  }
}
