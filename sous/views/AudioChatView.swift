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
    @State private var message: String = ""
    @State private var messageResponse: MessageResponse?
    @State private var isListenting: Bool = false
    @State var isThinking: Bool = false
    @StateObject private var speechManager = SpeechSynthesizerManager()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var audioEngine = AVAudioEngine()
    @State private var showAlert: Bool = false
    @State private var holdTimer: Timer?
    
    func setupSpeechManager() {
        speechManager.updateThinkingHandler = { newValue in
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
            GradientSphere(isSpeaking: $speechManager.isSpeaking, isThinking: $isThinking)
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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    speechManager.playYesChef()
                                    stopSpeechRecognition()
                                }
                            } else {
                                startListening()
                            }
                            isListenting.toggle()
                        }
                    }
                }
            if speechManager.isSpeaking || isListenting {
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
                        
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Long Press Detected"),
                message: Text(speechManager.useElevenLabsAPI ? "You held the press for 2 seconds. Expert mode enabled. 🧑‍🍳" : "Expert mode disabled"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onDisappear { holdTimer?.invalidate() }
    }
    
    
    private func startTimer() {
        holdTimer?.invalidate() // Invalidate any existing timer
        holdTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            self.showAlert = true
            speechManager.useElevenLabsAPI = !speechManager.useElevenLabsAPI
        }
    }


    private func startListening() {
        setupSpeechManager()
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
    
    private func stopSpeechRecognition() {
        isThinking = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
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
