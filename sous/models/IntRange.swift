//
//  IntRange.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//

import Foundation

struct IntRange: Codable {
    var start: Int
    var end: Int
    var stringValue: String {
            "\(start)-\(end)"
        }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ range: IntRange) {
        appendInterpolation("\(range.start)-\(range.end)")
    }
}
