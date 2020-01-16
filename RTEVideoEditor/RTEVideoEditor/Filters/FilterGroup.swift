//
//  filterGroup.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation

private struct FilterDescriptor {
    let identifier: String
    let type: RTEFilterType

    init(type: RTEFilterType) {
        self.identifier = type.rawValue
        self.type = type
    }
}

class FilterGroup {
    private var filterDescriptors: [FilterDescriptor] = []
    private var filtersMap: [String: RTEFilter] = [:]
    private var filtersParmasMap: [String: FilterParams] = [:]
    private let syncQueue: DispatchQueue
    
    init() {
        self.syncQueue = DispatchQueue(label: "Metal Renderer Sync Queue",
                                       qos: .`default`,
                                       attributes: [],
                                       autoreleaseFrequency: .inherit)
        
    }
    
    func render(pixelBuffer: CVPixelBuffer, context: RenderSharedContext) -> CVPixelBuffer {
        guard var outputPixelBuffer = context.pixelBufferPool.newPixelBufferFrom(pixelBuffer: pixelBuffer, copy: true) else {
            return pixelBuffer
        }
        
        self.filterDescriptors.forEach { (descriptor) in
            var filter: RTEFilter?
            if filtersMap[descriptor.identifier] == nil {
                switch descriptor.type {
                case .rosy: filter = RosyFilter(context: context)
                case .downsample: filter = DownsampleFilter(context: context)
                case .moon: filter = MoonFilter(context: context)
                case .sutro: filter = SutroFilter(context: context)
                case .rise: filter = RiseFilter(context: context)
                case .gaussian: filter = GaussianFilter(context: context)
                case .canvas: filter = CanvasFilter(context: context)
                }
                
                filtersMap[descriptor.identifier] = filter
            } else {
                filter = filtersMap[descriptor.identifier]!
            }
            
            if var filter = filter {
                filter.params = filtersParmasMap[descriptor.identifier]
                
                filter.prepare()
                outputPixelBuffer = filter.render(pixelBuffer: outputPixelBuffer)
            }
        }
        
        return outputPixelBuffer
    }
    
    func add(filter: RTEFilterType) {
        syncQueue.sync {
            if self.filterDescriptors.first(where: { $0.type == filter }) == nil {
                self.filterDescriptors.append(FilterDescriptor(type: filter))
                self.reorderFilters()
            } else {
                assertionFailure("Filter must be unique")
            }
        }
    }
    
    func update(filter: RTEFilterType, params: FilterParams) {
        syncQueue.sync {
            if let descriptor = self.filterDescriptors.first(where: { $0.type == filter }) {
                self.filtersParmasMap[descriptor.identifier] = params
            }
        }
    }
    
    func remove(filter: RTEFilterType) {
        syncQueue.sync {
            if let index = self.filterDescriptors.firstIndex(where: { $0.type == filter }) {
                self.filterDescriptors.remove(at: index)
            }
        }
    }
    
    private func reorderFilters() {
        self.filterDescriptors.sort { (l, r) -> Bool in
            return l.type.priority > r.type.priority
        }
    }
}
