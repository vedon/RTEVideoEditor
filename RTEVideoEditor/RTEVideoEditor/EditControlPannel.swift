//
//  EditControlPannel.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit

struct FilterItem {
    let descriptor: RTEFilterDescriptor
    var isSelected: Bool = false
}

extension RTEFilterType {
    var image: UIImage? {
        switch self {
        case .rosy: return nil
        case .downsample: return nil
        default: return nil
        }
    }
    
    var isReady: Bool {
        switch self {
        case .canvas: return false
        default: return true
        }
        
        return true
    }
}

class EditControlPannel {
    var filterItems: [FilterItem]
    
    init() {
        self.filterItems = RTEFilterType.allCases
                            .filter({ $0.isReady })
                            .map({ FilterItem(descriptor: RTEFilterDescriptor(type: $0)) })
    }
}
