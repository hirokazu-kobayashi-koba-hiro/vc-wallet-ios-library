//
//  InstanceCreator.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/11/05.
//
import Foundation

public func createInstance<T: NSObject>(className: String, type: T.Type) -> T? {
    
    guard let dynamicClass = NSClassFromString(className) as? T.Type else {
        Logger.shared.warn("className: \(className) is not found or not a valid NSObject subclass")
        return nil
    }
        
    return dynamicClass.init()
}


