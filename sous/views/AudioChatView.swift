//
//  AudioChat.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//
import SwiftUI
import Speech
import Combine


struct AudioChatView: View {
    @State private var messageResponse: MessageResponse?
    @State var isThinking: Bool = false
    @StateObject private var speechSynthesizerManager = SpeechSynthesizerManager()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var audioEngine = AVAudioEngine()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @State private var showAlert: Bool = false
    @State private var holdTimer: Timer?
    
    func setupSpeechManager() {
        speechSynthesizerManager.updateThinkingHandler = { newValue in
            self.isThinking = newValue
        }
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .edgesIgnoringSafeArea(.all)
                .gesture(
                LongPressGesture(minimumDuration: 2)
                .onChanged { _ in startTimer() }
                .onEnded { _ in holdTimer?.invalidate() }
                )
            GradientSphere(isSpeaking: $speechSynthesizerManager.isSpeaking, isThinking: $isThinking)
                .onAppear {
                    speechSynthesizerManager.playWelcome()
                }
                .onTapGesture {
                    withAnimation {
                        if speechSynthesizerManager.isSpeaking {
                            speechSynthesizerManager.synthesizer.stopSpeaking(at: .immediate)
                        }
                        else {
                            if speechRecognitionManager.isListening {
                                speechRecognitionManager.stopSpeechRecognition()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    speechSynthesizerManager.playYesChef()
                                }
                            } else {
                                startListeningNew()
                            }
                        }
                    }
                }
            if speechSynthesizerManager.isSpeaking || speechRecognitionManager.isListening {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        WaveformView()
                        Spacer()
                    }
                    Spacer()
                }
            } else if isThinking {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        LoadingAnimationView()
                        Spacer()
                    }
                    Spacer()
                }
            }
        }.onAppear {
            self.startListeningNew()
        }.onChange(of: speechRecognitionManager.isReadyToReport) { newState in
            if newState == true {
                sendRequestWithTranscript(transcript: speechRecognitionManager.recordedTranscript)
                speechRecognitionManager.clear()
            }
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Long Press Detected"),
                message: Text(speechSynthesizerManager.useElevenLabsAPI ? "You held the press for 2 seconds. Expert mode enabled. 🧑‍🍳" : "Expert mode disabled"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onDisappear { holdTimer?.invalidate() }
    }
    
    private func startListeningNew() {
        do {
            try speechRecognitionManager.startListening()
        } catch {
            print("Error starting speech recognition: \(error)")
        }
    }
    
    private func startTimer() {
        holdTimer?.invalidate() // Invalidate any existing timer
        holdTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            self.showAlert = true
            speechSynthesizerManager.useElevenLabsAPI = !speechSynthesizerManager.useElevenLabsAPI
        }
    }
    
    private func sendRequestWithTranscript(transcript: String) {
        isThinking = true
        print("Transcript updated: \(speechRecognitionManager.recordedTranscript)")
        getRecommendation(transcript: transcript)
    }
    
    
    
    private func getRecommendation(transcript: String) {
        let url = URL(string: "https://recipe-service-production.up.railway.app/v1/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the JSON payload with location data
        let payload: [String: Any] = [
            "content": transcript
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
                        speechSynthesizerManager.synthesizeSpeech(from: decodedResponse.content)
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
