//
//  EditControlPannel.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import UIKit

struct FilterItem {
    let type: RTEFilterType
    var isSelected: Bool = false
}

extension RTEFilterType {
    var isReady: Bool {
        switch self {
        default: return true
        }
    }
}

class EditControlPannel {
    var filterItems: [FilterItem]
    
    init() {
        self.filterItems = RTEFilterType.allCases
                            .filter({ $0.isReady })
                            .map({ FilterItem(type: $0) })
    }
}
