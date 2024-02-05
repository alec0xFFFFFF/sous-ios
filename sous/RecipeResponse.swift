//
//  RecipeResponse.swift
//  sous
//
//  Created by Alexander K White on 2/3/24.
//

import Foundation

struct RecipeResponse: Codable, Identifiable {
    var id: Int
    var author: String?
    var createdAt: String
    var deleted: Bool
    var description: String
    var equipment: String
    var ingredients: String
    var servings: Int?
    var steps: String
    var submissionMd5: String
    var time: String?
    var title: String

    enum CodingKeys: String, CodingKey {
        case id, author, deleted, description, equipment, ingredients, servings, steps, time, title
        case createdAt = "created_at"
        case submissionMd5 = "submission_md5"
    }
}
