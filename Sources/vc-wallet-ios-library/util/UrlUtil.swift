//
//  UrlUtil.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation

public func extractScheme(_ urlValue: String) -> String? {

  guard let url = URL(string: urlValue) else {
    return nil
  }

  return url.scheme
}

public func extractQueriesAsSingleMap(_ urlValue: String) -> [String: String] {

  var queryMap = [String: String]()

  guard let url = URL(string: urlValue) else {
    return [:]
  }

  if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
    let queryItems = components.queryItems
  {
    for queryItem in queryItems {
      queryMap[queryItem.name] = queryItem.value
    }
  }

  return queryMap
}
