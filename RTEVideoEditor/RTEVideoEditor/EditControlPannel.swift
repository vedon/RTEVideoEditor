//
//  EditControlPannel.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit

struct FilterItem {
    let filter: RTEFilter
    var isSelected: Bool = false
}

extension RTEFilterType {
    var desc: String {
      switch self {
        case .rosy: return "rosy"
        case .downsample: return "downsample"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .rosy: return nil
        case .downsample: return nil
        }
    }
    
    var isReady: Bool {
        switch self {
        case .downsample: return false
        default: return true
        }
    }
}

class EditControlPannel {
    var filterItems: [FilterItem]
    
    init() {
        self.filterItems = RTEFilterType.allCases
                            .filter({ $0.isReady })
                            .map({ FilterItem(filter: RTEFilter(type: $0)) })
    }
}
