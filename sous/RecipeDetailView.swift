//
//  RecipeDetailView.swift
//  sous
//
//  Created by Alexander K White on 2/3/24.
//
import SwiftUI

struct RecipeDetailView: View {
    let recipeId: Int
    @State private var recipe: RecipeResponse? = nil
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let recipe = recipe {
                Text("Title: \(recipe.title )")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Author: \(recipe.author ?? "Unknown")")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Description: \(recipe.description )")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Equipment: \(recipe.equipment )")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Ingredients: \(recipe.ingredients )")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Servings: \(recipe.servings.map(String.init) ?? "Not Specified")")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Steps: \(recipe.steps )")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationBarTitle("Recipe Details", displayMode: .inline)
        .onAppear(perform: loadFullRecipe)
    }
        
    func loadFullRecipe() {
            isLoading = true
            // Replace with the actual URL and logic to fetch the full recipe details
            let url = URL(string: "https://recipe-service-production.up.railway.app/v1/recipes/\(recipeId)")!

            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let data = data {
                        recipe = try? JSONDecoder().decode(RecipeResponse.self, from: data)
                    }
                }
            }.resume()
        }
}
