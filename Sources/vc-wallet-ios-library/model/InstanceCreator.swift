//
//  InstanceCreator.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/11/05.
//
import Foundation

public func createInstance<T>(className: String, type: T.Type) -> T? {
    
    if let dynamicClass = NSClassFromString(className) as? NSObject.Type {
        let instance = dynamicClass.init()
        return instance as? T
    }
    
    Logger.shared.warn("className: \(className) is not found")
    return nil
}


