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
        ScrollView {
            VStack(alignment: .leading) {
                if isLoading {
                    ProgressView()
                } else if let recipe = recipe {
                    Group {
                        Text("Title: \(recipe.title)")
                        Text("Author: \(recipe.author ?? "Unknown")")
                        Text("Description: \(recipe.description)")
                        Text("Equipment: \(recipe.equipment)")
                        Text("Ingredients: \(recipe.ingredients)")
                        Text("Servings: \(recipe.servings?.stringValue ?? "N/A")")
                        Text("Steps: \(recipe.steps)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }.padding()
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
