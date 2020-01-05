//
//  VideoPlayerLayer.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2019/12/30.
//  Copyright © 2019 Free. All rights reserved.
//

import UIKit

typealias Drawable = Any

protocol VideoPlayerLayer: UIView {
    func nextDrawable() -> Drawable?
}


