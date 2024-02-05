//
//  CaptureView.swift
//  sous
//
//  Created by Alexander K White on 11/25/23.
//

import SwiftUI
import CoreLocation


struct CaptureView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var restaurantName: String = ""
    @State private var mealName: String = ""
    @State private var price: String = ""
    @State private var review: String = ""
    @State private var images: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var sendingRequest: Bool = false
    @State private var showSourcePicker: Bool = false
    @State private var logRestaurant: Bool = false
    @State private var recipeResponse: RecipeResponse?
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary

    @State private var selectedOption = "Recipe"
        let options = ["Meal", "Ingredient", "Recipe"]
    
    let textFieldBackgroundColor = Color(red: 197.0 / 255.0, green: 219.0 / 255.0, blue: 218.0 / 255.0)
    let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 111.0 / 255.0, green: 137.0 / 255.0, blue: 135.0 / 255.0), Color(red: 0.62, green: 0.76, blue: 0.76), Color(red: 197.0 / 255.0, green: 219.0 / 255.0, blue: 218.0 / 255.0)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        NavigationView {
            VStack {
                
                Form {
                    Picker("Log Option", selection: $selectedOption) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                       ForEach(images.indices, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .onTapGesture {
                                    images.remove(at: index)
                                }
                        }
                    }
                }
                
                
                Button(action: {
                    showSourcePicker = true
                }) {
                    Label("Add Photo", systemImage: "camera")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .actionSheet(isPresented: $showSourcePicker) {
                    ActionSheet(
                        title: Text("Select Photo"),
                        buttons: [
                            .default(Text("Camera")) { imageSource = .camera; showImagePicker = true },
                            .default(Text("Photo Library")) { imageSource = .photoLibrary; showImagePicker = true },
                            .cancel()
                        ]
                    )
                }.sheet(isPresented: $showImagePicker) {
                    ImagePicker(images: $images, sourceType: imageSource)
                }
                .padding()
                
                // Additional UI depending on the selected option
                if selectedOption == "Meal" {
                    // UI for logging a meal
                    ZStack {
                        Rectangle()
                            .fill(textFieldBackgroundColor)
                            .cornerRadius(8)
                        TextField("Enter restaurant name", text: $restaurantName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                    }
                    ZStack {
                        Rectangle()
                            .fill(textFieldBackgroundColor)
                            .cornerRadius(8)
                        TextField("Enter meal name", text: $mealName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                    }
                    ZStack {
                        Rectangle()
                            .fill(textFieldBackgroundColor)
                            .cornerRadius(8)
                        TextField("Enter price", text: $price)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .padding()
                    }
                    
                    ZStack {
                        Rectangle()
                            .fill(textFieldBackgroundColor)
                            .cornerRadius(8)
                        TextField("Enter review", text: $review)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        
                    }
                    
                    Button(action: logMeal) {
                        Text("Log Meal")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .background(sendingRequest ? Color.gray.opacity(0.5) : Color.blue)
                            .disabled(sendingRequest)
                    }
                    .padding()
                } else if selectedOption == "Ingredient" {
                    // UI for logging an ingredient
                    Button(action: addIngredient) {
                        Text("Add Ingredient")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sendingRequest ? Color.gray.opacity(0.5) : Color.blue)
                            .cornerRadius(10)
                            .disabled(sendingRequest)
                    }
                    .padding()
                } else if selectedOption == "Recipe" {
                    // UI for logging a recipe
                    Button(action: {addRecipe(images)}) {
                        Text("Add Recipe")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sendingRequest ? Color.gray.opacity(0.5) : Color.blue)
                            .cornerRadius(10)
                            .disabled(sendingRequest)
                    }
                    .padding()
                    if let recipe = recipeResponse, recipe.id != -1 {
                        Text("Last Recipe Submitted:")
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
                        Button(action: {deleteRecipe(recipeId: recipe.id)}) {
                            Text("Delete Recipe")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(sendingRequest ? Color.gray.opacity(0.5) : Color.red)
                                .cornerRadius(10)
                                .disabled(sendingRequest)
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Capture")
            .onTapGesture {
                    self.hideKeyboard()
                }
            .background(gradient) // Apply the gradient as the background
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Request Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func addIngredient() {
        sendingRequest = true
        sendingRequest = false
    }
    
    private func addRecipe(_ recipe_images: [UIImage]) {
        sendingRequest = true
        let url = URL(string: "https://recipe-service-production.up.railway.app/v1/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        for (index, image) in images.enumerated() {

            var imageData = image.pngData()
            var compression: CGFloat = 1.0
            while let data = imageData, data.count > 1048576 && compression > 0 {
                compression -= 0.1
                imageData = image.jpegData(compressionQuality: compression)
            }
            guard let finalImageData = imageData else { continue }

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"recipe\"; filename=\"image\(index).png\"\r\n")
            body.append("Content-Type: image/png\r\n\r\n")
            body.append(finalImageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data) {
                    self.recipeResponse = decodedResponse
                } else {
                    alertMessage = "Failed to add recipe"
                    showAlert = true
                    print("Failed to decode response")
                }
            } else if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                print("Error in request: \(error.localizedDescription)")
            }
        }
            sendingRequest = false
        }.resume()
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
                alertMessage = error.localizedDescription
                showAlert = true
                print("Error during DELETE request: \(error.localizedDescription)")
                return
            }
            // Handle the response and update your UI accordingly
        }.resume()
    }
    
    private func logMeal() {
        // TODO add images
        // TODO after post navigate to the post?
        sendingRequest = true
        guard let url = URL(string: "https://flask-production-e498.up.railway.app/api/v1/meal") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")


        let mealData = [
            "restaurantName": restaurantName,
            "mealName": mealName,
            "price": price,
            "review": review,
            // Add images or other data as needed
        ]

        do {
            var body = Data()

            // Append text fields
            for (key, value) in mealData {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }

            // Append images
            for image in images {
                let filename = "image\(images.firstIndex(of: image) ?? 0).jpg"
                let mimeType = "image/jpeg"
                guard let imageData = image.jpegData(compressionQuality: 1) else { continue }

                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"\(filename)\"\r\n")
                body.append("Content-Type: \(mimeType)\r\n\r\n")
                body.append(imageData)
                body.append("\r\n")
            }

            body.append("--\(boundary)--\r\n")

            // Set the body of the request
            request.httpBody = body

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    sendingRequest = false
                    return
                }
                // Handle the response here
            }
            task.resume()
        } catch {
            print("Error: \(error)")
        }
        sendingRequest = false
    }

}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

struct CaptureView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureView()
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
