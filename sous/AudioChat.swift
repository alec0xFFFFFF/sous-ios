//
//  AudioChat.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//
import SwiftUI
import Speech


struct AudioChatView: View {
    @State private var message: String = ""
    @State private var messageResponse: MessageResponse?
    @State private var isListenting: Bool = false
    @State private var isThinking: Bool = false
    @StateObject private var speechManager = SpeechSynthesizerManager()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var audioEngine = AVAudioEngine()
    
    
    var body: some View {
        ZStack {
            GradientSphere(isSpeaking: $speechManager.isSpeaking)
                .onAppear {
                    speechManager.playWelcome()
                }
                .onTapGesture {
                    withAnimation {
                        if speechManager.isSpeaking {
                            speechManager.synthesizer.stopSpeaking(at: .immediate)
                        }
                        else {
                            if isListenting {
                                speechManager.playYesChef()
                                stopListening()
                            } else {
                                startListening()
                            }
                            isListenting.toggle()
                        }
                    }
                }
            Text("👨‍🍳")
                            .font(.system(size: 60))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

struct GradientSphere: View {
    @Binding var isSpeaking: Bool
    @State private var gradientCenter = UnitPoint(x: 0.5, y: 0.5)
    
    @State private var scale: CGFloat = 1.0

    var body: some View {
        let colors: [Color] = isSpeaking ? [.red, .orange] : [.purple, .blue]
        let gradient = RadialGradient(gradient: Gradient(colors: colors), center: gradientCenter, startRadius: 5, endRadius: 200)

        Circle()
            .fill(gradient)
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    gradientCenter = UnitPoint(x: 0, y: 0)
                }
            }
            .onChange(of: isSpeaking) { newValue in
                withAnimation(.easeInOut(duration: 0.5)) {
                    scale = newValue ? 1.2 : 1.0
                }
            }
    }
}
