//
//  SpeechRecognitionManager.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//
import Foundation
import Speech
import AVFoundation

class SpeechRecognitionManager: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5
    private var keyPhraseDetected = false
    private var transcriptStartPosition = 0
    @Published var recordedTranscript: String = "" // Publicly accessible transcript
    @Published var isListening: Bool = false
    @Published var isReadyToReport: Bool = false

    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        super.init()
        speechRecognizer.delegate = self
    }

    func startListening() throws {
        if recognitionTask != nil {
            stopSpeechRecognition()
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode

        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result, self.isListening {
                let transcription = result.bestTranscription.formattedString

                if transcription.lowercased().contains("chef") && !self.keyPhraseDetected {
                    self.recordedTranscript = "" // Clear the recorded transcript
                    self.keyPhraseDetected = true
                    self.transcriptStartPosition = result.bestTranscription.segments.last?.substringRange.location ?? 0
                }

                if self.keyPhraseDetected {
                    let startIndex = transcription.index(transcription.startIndex, offsetBy: self.transcriptStartPosition)
                    self.recordedTranscript = String(transcription[startIndex...])
                    self.resetSilenceTimer()
                }
            } else if let error = error {
                print("Speech recognition error: \(error)")
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        self.isListening = true
    }

    private func stopRecording() {
        print("Captured Transcript: \(recordedTranscript)")
        keyPhraseDetected = false
        self.isListening = false
        self.isReadyToReport = true
    }

    func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceTimer?.invalidate()
        stopRecording()
    }

    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }

    private func resetSilenceTimer() {
        startSilenceTimer()
    }

    // Implement any necessary SFSpeechRecognizerDelegate methods
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle the availability change
    }
    
    func enable() {
        self.isListening = true
    }
    
    func disable() {
        self.isListening = false
    }
    
    func clear() {
        self.isReadyToReport = false
    }
}
