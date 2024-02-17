//
//  MessageResponse.swift
//  sous
//
//  Created by Alexander K White on 2/16/24.
//

import Foundation

struct MessageResponse: Codable {
    var content: String

    enum CodingKeys: String, CodingKey {
        case content
    }
}
