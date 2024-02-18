//
//  SpeechSynthesizerManager.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//

import Foundation
import AVFoundation
import Speech

class SpeechSynthesizerManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    @Published var isSpeaking: Bool = false
    let synthesizer = AVSpeechSynthesizer()
    var audioPlayer: AVAudioPlayer?
    var useElevenLabsAPI: Bool = true // Flag to toggle between AVSpeechSynthesizer and ElevenLabs API

    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    private func listVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            print("Voice: \(voice.name), Language: \(voice.language), Identifier: \(voice.identifier)")
        }
    }
    
    func synthesizeSpeech(from text: String) {
        isSpeaking = true

        if useElevenLabsAPI {
            fetchSpeechFromElevenLabs(from: text)
        } else {
            synthesizeSpeechUsingAVSpeechSynthesizer(from: text)
        }
    }
    
    private func fetchSpeechFromElevenLabs(from: String) {
            let voiceId = "xNx17ebeAzBxoUz7iepQ"
            let modelID = "eleven_multilingual_v2"
            let apiUrl = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
            var request = URLRequest(url: apiUrl)
            // todo don't commit this key
            request.addValue("", forHTTPHeaderField: "xi-api-key")
        
            request.addValue("application/json", forHTTPHeaderField:"Content-Type")

            request.httpMethod = "POST"
            let payload: [String: Any] = [
                "model_id": modelID,
                "text": from,
                "voice_settings": [
                    "stability": 0.5,
                    "similarity_boost": 0.5
                ]
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                print("Error: Unable to serialize payload to JSON")
                return
            }
        
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data {
                    self.playAudio(data: data)
                } else {
                    print("Error fetching speech: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self.isSpeaking = false
                    }
                }
            }.resume()
    }
    
    func curlString(from request: URLRequest) -> String {
        guard let url = request.url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"

        if request.httpMethod == "GET" {
            baseCommand += " -X GET"
        } else if let method = request.httpMethod {
            baseCommand += " -X \(method)"
        }

        if let headers = request.allHTTPHeaderFields {
            for (header, value) in headers {
                baseCommand += " -H \"\(header): \(value)\""
            }
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            baseCommand += " -d '\(bodyString)'"
        }

        return baseCommand
    }

    private func playAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func synthesizeSpeechUsingAVSpeechSynthesizer(from text: String) {
        isSpeaking = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        let utterance = AVSpeechUtterance(string: text)

        let voice = AVSpeechSynthesisVoice(language: "en-US")

        utterance.voice = voice
        synthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func playYesChef() {
        guard let path = Bundle.main.path(forResource: "yes_chef", ofType: "mp3") else { return }
        playSound(path: path)
    }
    
    func playWelcome() {
        guard let path = Bundle.main.path(forResource: "what_should_we_cook", ofType: "mp3") else { return }
        playSound(path: path)
    }
    
    func playSound(path: String) {
        let url = URL(fileURLWithPath: path)
        do {
            self.isSpeaking = true
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self // Set the delegate to self
            audioPlayer?.play()
        } catch {
            // Handle the error
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
            print("Could not load the audio file: \(error)")
        }
    }

}
