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
    @Published var useElevenLabsAPI: Bool = false
    var updateThinkingHandler: ((Bool) -> Void)?
    @Published private var elevenLabsApiKey: String = ""
    
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
        if useElevenLabsAPI {
            fetchSpeechFromElevenLabs(from: text)
        } else {
            synthesizeSpeechUsingAVSpeechSynthesizer(from: text)
        }
    }
    
    private func fetchElevenLabsKey() -> Result<String, Error> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<String, Error>!

        let apiUrl = URL(string: "https://recipe-service-production.up.railway.app/v1/eleven-labs")!
        let request = URLRequest(url: apiUrl)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                result = .failure(error)
            } else if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    result = .success(responseString)
                } else {
                    result = .failure(URLError(.cannotDecodeContentData))
                }
            }
            semaphore.signal()
        }.resume()

        semaphore.wait()
        return result
    }
    
    private func getElevenLabsKey() -> String{
        if elevenLabsApiKey == "" {
            let result = fetchElevenLabsKey()
            switch result {
                case .success(let responseString):
                    self.elevenLabsApiKey = responseString
                    return responseString
                case .failure(let error):
                    print("Error fetching eleven labs key: \(error.localizedDescription)")
                    return ""
                }
        }
        return elevenLabsApiKey
    }
    
    private func fetchSpeechFromElevenLabs(from: String) {
        let elevenLabsKey = getElevenLabsKey()
        self.updateThinkingHandler?(true)
        let voiceId = "xNx17ebeAzBxoUz7iepQ"
        let modelID = "eleven_multilingual_v2"
        let apiUrl = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
        var request = URLRequest(url: apiUrl)
        
        request.addValue(elevenLabsKey, forHTTPHeaderField: "xi-api-key")
    
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
                print(data)
                self.updateThinkingHandler?(false)
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
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            // Handle the error
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
            print("Could not load the audio file: \(error)")
        }
    }
    
    private func playAudio(data: Data) {
        do {
            self.isSpeaking = true
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
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

}
