//
//  MakeLayout.swift
//  FilterCapture
//
//  Created by kim sunchul on 2021/07/03.
//  Copyright © 2021 sc.kim. All rights reserved.
//

import Foundation

protocol MakeLayout: class {
  var didMakeConstraints: Bool { get set }

  func makeLayout()
  func addSubViews()
  func makeConstraintsIfNeeded()
  func makeConstraints()
}


extension MakeLayout {

  func makeLayout() {
    self.addSubViews()
    self.makeConstraintsIfNeeded()
  }

  func makeConstraintsIfNeeded() {
    if !self.didMakeConstraints {
      self.makeConstraints()
      self.didMakeConstraints = true
    }
  }
}
