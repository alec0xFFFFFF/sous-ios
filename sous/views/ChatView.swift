//
//  ChatView.swift
//  sous
//
//  Created by Alexander K White on 11/25/23.
//

import SwiftUI
import CoreLocation

struct ChatView: View {
    @State private var messageText: String = ""
    @State private var receivedMessages: [String] = []
    @State private var isSendingMessage: Bool = false
    @StateObject private var locationService = LocationService()
    @State private var errorMessage: String? // For displaying errors

    let customBackgroundColor = Color(red: 0.62, green: 0.76, blue: 0.76)
    let textFieldBackgroundColor = Color(red: 197.0 / 255.0, green: 219.0 / 255.0, blue: 218.0 / 255.0)

    let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 111.0 / 255.0, green: 137.0 / 255.0, blue: 135.0 / 255.0), Color(red: 0.62, green: 0.76, blue: 0.76), Color(red: 197.0 / 255.0, green: 219.0 / 255.0, blue: 218.0 / 255.0)]),
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            VStack {
                if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                ScrollView {
                    LazyVStack {
                        ForEach(receivedMessages, id: \.self) { message in
                            HStack {
                                Text(message)
                                    .padding().background(textFieldBackgroundColor)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                    .onLongPressGesture {
                                        UIPasteboard.general.string = message
                                    }
                                Spacer()
                            }
                        }
                    }
                }

                HStack {
                    ZStack {
                        Rectangle()
                            .fill(textFieldBackgroundColor)
                            .cornerRadius(8)
                        TextField("Type your message here...", text: $messageText)
                            .padding(.horizontal)
                        
                    }
                    .frame(height: 60)
                    .padding(.horizontal)
                    if isSendingMessage {
                        ProgressView()
                            .padding(.horizontal)
                    } else {
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.primary)
                        }
                        .disabled(messageText.isEmpty)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    }
                }
                .padding()
                
                NavigationLink(destination: CaptureView()) {
                                    Text("Record Meal")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .navigationBarTitle("Sous Chat 🧑‍🍳")
            }
            .onAppear {
                locationService.requestLocation()
            }
            .background(gradient) // Apply the gradient as the background
        }
    }

    func sendMessage() {
        isSendingMessage = true
        let messageToSend = messageText
        receivedMessages.append(messageToSend) // Display the user's message in the messages
        messageText = "" // Clear the message input field

        // Use a default location if the actual location is not available
        let location = locationService.lastKnownLocation ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let locationName = locationService.locationName ?? "Unknown"

        // Prepare the URL and URLRequest
        let url = URL(string: "https://flask-production-e498.up.railway.app/api/v1/recommend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the JSON payload with location data
        let payload: [String: Any] = [
            "message": messageToSend,
            "latitude": location.latitude,
            "longitude": location.longitude,
            "location_name": locationName
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode JSON payload")
            isSendingMessage = false
            return
        }
        
        // Perform the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSendingMessage = false
                if let error = error {
                    self.errorMessage = "Error sending message: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    let json = try JSONDecoder().decode([String: String].self, from: data)
                    if let message = json["message"] {
                        self.receivedMessages.append(message)
                    }
                } catch {                
                    self.errorMessage = "Failed to parse JSON response"
                }
            }
        }.resume()
    }
}

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    @Published var locationName: String?
    @Published var errorMessage: String? // For location errors



    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
        fetchLocationName(for: locations.first)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Error getting location: \(error.localizedDescription)"
    }

    private func fetchLocationName(for location: CLLocation?) {
        guard let location = location else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let placemark = placemarks?.first, let locality = placemark.locality {
                self?.locationName = locality
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
