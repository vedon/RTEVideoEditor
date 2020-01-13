//
//  FilterManager.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/4.
//  Copyright © 2020 Free. All rights reserved.
//

import AVFoundation
//https://github.com/alexiscn/MetalFilters
class FilterManager {
    private(set) var filterDescriptors: [RTEFilterDescriptor] = []
    private var filters: [String: RTEFilter] = [:]
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
            if filters[descriptor.identifier] == nil {
                switch descriptor.type {
                case .rosy: filter = RosyFilter(context: context)
                case .downsample: filter = DownsampleFilter(context: context)
                case .moon: filter = MoonFilter(context: context)
                case .sutro: filter = SutroFilter(context: context)
                case .rise: filter = RiseFilter(context: context)
                case .canvas: filter = CanvasFilter(context: context)
                }
                
                filters[descriptor.identifier] = filter
            } else {
                filter = filters[descriptor.identifier]!
            }
            
            if var filter = filter {
                filter.params = filtersParmasMap[descriptor.identifier]
                
                filter.prepare()
                outputPixelBuffer = filter.render(pixelBuffer: outputPixelBuffer)
            }
        }
        
        return outputPixelBuffer
    }
    
    func add(filterDescriptor: RTEFilterDescriptor) {
        syncQueue.sync {
            self.filterDescriptors.append(filterDescriptor)
        }
    }
    
    func update(filterDescriptor: RTEFilterDescriptor, params: FilterParams) {
        syncQueue.sync {
            self.filtersParmasMap[filterDescriptor.identifier] = params
        }
    }
    
    func remove(filterDescriptor: RTEFilterDescriptor) {
        syncQueue.sync {
            if let index = self.filterDescriptors.firstIndex(where: { $0.identifier == filterDescriptor.identifier }) {
                self.filterDescriptors.remove(at: index)
            }
        }
    }
}
