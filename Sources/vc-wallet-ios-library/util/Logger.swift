//
//  Logger.swift
//
//
//  Created by 小林弘和 on 2024/09/21.
//

import Foundation

public final class Logger: Sendable {

  public static let shared = Logger()

  private init() {}

  public func debug(_ message: String) {
    #if DEBUG
      log(message, level: .debug)
    #endif
  }

  public func info(_ message: String) {
    log(message, level: .info)
  }

  public func warn(_ message: String) {
    log(message, level: .warning)
  }

  public func error(_ message: String) {
    log(message, level: .error)
  }

  private func log(_ message: String, level: LogLevel) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
    print("[\(timestamp)] [\(level.rawValue)] - \(message)")
  }
}

enum LogLevel: String {
  case debug = "DEBUG"
  case info = "INFO"
  case warning = "WARNING"
  case error = "ERROR"
}
