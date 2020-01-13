//
//  CGSize+extension.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit
extension CGSize {
    func isValid() -> Bool {
        return self.width != 0 && self.height != 0
    }
    
    func ratio() -> CGFloat {
        return self.width / self.height
    }
}
