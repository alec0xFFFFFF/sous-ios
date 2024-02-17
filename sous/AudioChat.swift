//
//  AudioChat.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//
import SwiftUI
import AVFoundation
import Speech

class SpeechSynthesizerManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking: Bool = false
    let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func synthesizeSpeech(from text: String) {
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

}


struct AudioChatView: View {
    @State private var message: String = ""
    @State private var messageResponse: MessageResponse?
    @State private var isListenting: Bool = false
    @State private var isThinking: Bool = false
    @StateObject private var speechManager = SpeechSynthesizerManager()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var audioEngine = AVAudioEngine()
    
    
    var body: some View {
        VStack {
            if speechManager.isSpeaking {
                Button("Yes, Chef.") {
                    speechManager.synthesizer.stopSpeaking(at: .immediate)
                }
            } else if isThinking {
                Text("Thinking...")
            } else {
                Button(isListenting ? "Stop Listening" : "Start Listening") {
                if isListenting {
                    stopListening()
                } else {
                    startListening()
                }
                isListenting.toggle()
            }
            }
        }
    }


    private func startListening() {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode // Directly using inputNode as it's non-optional
        
        recognitionRequest.shouldReportPartialResults = true
        speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            if let result = result {
                self.message = result.bestTranscription.formattedString
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        // this crashes in preview
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try! audioEngine.start()
    }

    private func stopListening() {
        isThinking = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        // send request in text to server
        // receive response just as text and immediately play it
        getRecommendation()
    }
    
    private func listVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            print("Voice: \(voice.name), Language: \(voice.language), Identifier: \(voice.identifier)")
        }
    }
    
    private func getRecommendation() {
        let url = URL(string: "https://recipe-service-production.up.railway.app/v1/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the JSON payload with location data
        let payload: [String: Any] = [
            "content": message
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode JSON payload")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    isThinking = false
                    print("\(error)")
                    return
                }
                
                guard let data = data else {
                    isThinking = false
                    return
                }
                
                do {
                    if let decodedResponse = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                        self.messageResponse = decodedResponse
                        speechManager.synthesizeSpeech(from: decodedResponse.content)
                        isThinking = false
                    }
                } catch {
                    isThinking = false
                    print("decoding error")
                }
            }
        }.resume()
    }
}

struct AudioChatView_Previews: PreviewProvider {
    static var previews: some View {
        AudioChatView()
    }
}
