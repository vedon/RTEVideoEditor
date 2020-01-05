//
//  Logger.swift
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

import Foundation

class Logger {
    static let shared = Logger()
    
    func transfrom(_ msg: String) {
        print("🗿: \(msg)")
    }
    
    func image(_ msg: String) {
        print("🖼: \(msg)")
    }
    
    func warn(_ msg: String) {
        print("⚠️: \(msg)")
    }
}
