//
//  AudioStreamView.swift
//  sous
//
//  Created by Alexander K White on 2/19/24.
//

import Foundation
import AVFoundation
import SwiftUI


class AudioViewModel: ObservableObject {
    var player: AVPlayer?
    private var dataTask: URLSessionDataTask?

    func playStreamFromServer(userQuery: String) {
        guard let url = URL(string:  "https://recipe-service-production.up.railway.app/v1/tts") else { 
            print("url error")
            return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyData = ["query": userQuery]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData, options: [])

        // Use URLSession to send a POST request
        let session = URLSession.shared
        dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("Error making request: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }

            // Play the received audio data
            self.playAudio(fromData: data)
        }
        dataTask?.resume()
    }

    private func playAudio(fromData data: Data) {
        DispatchQueue.main.async {
            do {
                let temporaryURL = self.writeDataToTemporaryFile(data)
                let asset = AVURLAsset(url: temporaryURL)
                let playerItem = AVPlayerItem(asset: asset)
                self.player = AVPlayer(playerItem: playerItem)
                self.player?.play()
            } catch {
                print("Failed to play audio: \(error.localizedDescription)")
            }
        }
    }

    private func writeDataToTemporaryFile(_ data: Data) -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("tempAudio")
        try? data.write(to: temporaryFileURL)
        return temporaryFileURL
    }
}


struct ContentView: View {
    @StateObject var audioViewModel = AudioViewModel()

    var body: some View {
        VStack {
            Button("Play Audio") {
                audioViewModel.playStreamFromServer(userQuery: "tell me about the city of san francisco")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
