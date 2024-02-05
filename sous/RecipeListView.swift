//
//  RecipeListView.swift
//  sous
//
//  Created by Alexander K White on 2/3/24.
//
import SwiftUI

struct RecipeListView: View {
    @State private var query: String = "italian"
    @State private var dishes: DishesResponse? = nil
    @State private var isLoading = false
    @State private var selectedRecipeId: Int?
    @State private var isShowingDetailView = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for recipes", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    loadRecipes()
                }

                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(dishes?.dishes ?? [], id: \.id) { recipe in
                            VStack(alignment: .leading) {
                                Text("Title: \(recipe.title)")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Author: \(recipe.author)")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Description: \(recipe.description)")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .onTapGesture {
                                self.selectedRecipeId = recipe.id
                                self.isShowingDetailView = true
                            }
                        }
                        .onDelete(perform: deleteDish)
                    }
                }

            }
            .sheet(isPresented: $isShowingDetailView) {
                if let selectedRecipeId = selectedRecipeId {
                    RecipeDetailView(recipeId: selectedRecipeId)
                }
            }
            .navigationBarTitle("Recipes")
        }
        .onAppear(perform: loadRecipes)
    }
    
    func deleteDish(at offsets: IndexSet) {
        offsets.forEach { index in
            let recipeId = dishes?.dishes[index].id
            deleteRecipe(recipeId: recipeId!)
        }
        dishes?.dishes.remove(atOffsets: offsets)
    }
    
    func deleteRecipe(recipeId: Int) {
        guard let url = URL(string: "https://recipe-service-production.up.railway.app/v1/recipes/\(recipeId)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during DELETE request: \(error.localizedDescription)")
                return
            }
            // Handle the response and update your UI accordingly
        }.resume()
    }

    func loadRecipes() {
        isLoading = true
        guard let url = URL(string: "https://recipe-service-production.up.railway.app/v1/?query=\(query)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(DishesResponse.self, from: data)
                        self.dishes = decodedResponse
                    } catch {
                        print("Failed to decode DishesResponse: \(error)")
                        
                        // If you need more detailed error information:
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .dataCorrupted(let context):
                                print("Data corrupted: \(context.debugDescription)")
                            case .keyNotFound(let key, let context):
                                print("Key '\(key)' not found: \(context.debugDescription)")
                            case .typeMismatch(let type, let context):
                                print("Type mismatch for type \(type): \(context.debugDescription)")
                            case .valueNotFound(let value, let context):
                                print("Value '\(value)' not found: \(context.debugDescription)")
                            @unknown default:
                                print("Unknown decoding error: \(decodingError)")
                            }
                        } else {
                            print("Other error: \(error)")
                        }
                    }
                } else if let error = error {
                    print("Error in request: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView()
    }
}
