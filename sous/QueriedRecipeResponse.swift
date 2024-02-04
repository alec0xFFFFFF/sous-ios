//
//  QueriedRecipeResponse.swift
//  sous
//
//  Created by Alexander K White on 2/3/24.
//

import Foundation

struct QueriedRecipeResponse: Codable, Identifiable {
    var id: String
    var author: String
    var title: String
    var description: String

    enum CodingKeys: String, CodingKey {
        case id, author, title, description
    }
}

