//
//  DateAdapter.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/14.
//

import Foundation

func nowAsEpochSecond() -> Int64 {
  // Adjust the current date by subtracting 9 hours (timezone fix)
  let currentDate = Date()
  let adjustedDate = Calendar.current.date(byAdding: .hour, value: 0, to: currentDate)!
  return Int64(adjustedDate.timeIntervalSince1970)
}
