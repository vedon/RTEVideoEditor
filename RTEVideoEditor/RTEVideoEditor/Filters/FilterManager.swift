//
//  FilterManager.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation

class FilterManager {
    private(set) var filters: [RTEFilter] = []
    private var filtersImp: [String: RTEFilterImp] = [:]
    private var filtersParmasMap: [String: FilterParams] = [:]
    private let syncQueue: DispatchQueue
    
    init() {
        self.syncQueue = DispatchQueue(label: "Metal Renderer Sync Queue",
                                       qos: .`default`,
                                       attributes: [],
                                       autoreleaseFrequency: .inherit)
        
    }
    
    func render(pixelBuffer: CVPixelBuffer, context: FilterSharedContext) -> CVPixelBuffer {
        var outputPixelBuffer = pixelBuffer
        self.filters.forEach { (filter) in
            var filterImp = filtersImp[filter.identifier]
            if filterImp == nil {
                switch filter.type {
                case .rosy: filterImp = RosyFilter()
                case .downsample: filterImp = DownsampleFilter()
                }
            }
            filterImp?.context = context
            
            filterImp?.params = filtersParmasMap[filter.identifier]
            
            filterImp?.prepare()
            
            outputPixelBuffer = filterImp!.render(pixelBuffer: outputPixelBuffer)
        }
        
        return outputPixelBuffer
    }
    
    func add(filter: RTEFilter) {
        syncQueue.sync {
            self.filters.append(filter)
        }
    }
    
    func update(filter: RTEFilter, params: FilterParams) {
        syncQueue.sync {
            self.filtersParmasMap[filter.identifier] = params
        }
    }
    
    func remove(filter: RTEFilter) {
        syncQueue.sync {
            if let index = self.filters.firstIndex(where: { $0.identifier == filter.identifier }) {
                self.filters.remove(at: index)
            }
        }
    }
}
