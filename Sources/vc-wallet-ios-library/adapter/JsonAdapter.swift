//
//  JsonAdapter.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/08.
//
import Foundation

public func readFromJson(_ data: Data) -> [String: Any]? {

  guard !data.isEmpty else {
    return [:]
  }

  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
  Logger.shared.debug("Response: \(jsonObject)")
  guard let dictionary = jsonObject as? [String: Any] else {
    return nil
  }

  return dictionary
}

public func readFromJson<T: Decodable>(_ data: Data, responseType: T.Type, enableSnakeCase: Bool)
  -> T?
{

  let decoder = JSONDecoder()
  if enableSnakeCase {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  return try? decoder.decode(T.self, from: data)
}

public func writeToJson(_ object: Codable) -> String? {

  let encoder = JSONEncoder()
  let data = try? encoder.encode(object)

  guard let data else {
    return nil
  }

  return String(data: data, encoding: .utf8)!
}
