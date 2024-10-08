//
//  JsonUtil.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/08.
//
import Foundation

public func parse(_ data: Data) throws -> [String: Any] {
        guard !data.isEmpty else {
            return [:]
        }
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        Logger.shared.debug("Response: \(jsonObject)")
        guard let dictionary = jsonObject as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return dictionary
}


