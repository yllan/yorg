//
//  YIView.swift
//  yorg
//
//  Created by Yung-Luen Lan on 2019/1/23.
//  Copyright © 2019 yllan. All rights reserved.
//

import Foundation

struct YIPoint {
    var x: Int
    var y: Int
    static let zero = YIPoint(x: 0, y: 0)
}

struct YISize {
    var width: Int
    var height: Int
    static let zero = YISize(width: 0, height: 0)
}

struct YIRect {
    var origin: YIPoint
    var size: YISize
    
    static let zero = YIRect(origin: .zero, size: .zero)
}

class YIView {
    var frame: YIRect = .zero
    var subviews: [YIView] = []
    weak var superview: YIView? = nil
    
    init() {
        
    }
}
