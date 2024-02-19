//
//  SpeechRecognitionManager.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//

import Foundation
import Speech

class SpeechRecognitionManager: NSObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.0

    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        super.init()
        speechRecognizer.delegate = self
    }

    func startListening() throws {
        if recognitionTask != nil {
            // A recognition task is already in progress
            stopSpeechRecognition()
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode // Direct use without optional binding

        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                // Handle the speech recognition result here
                print(result.bestTranscription.formattedString)
                self?.resetSilenceTimer()
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
        startSilenceTimer()
    }


    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceTimer?.invalidate()
    }

    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            self?.stopSpeechRecognition()
        }
    }

    private func resetSilenceTimer() {
        startSilenceTimer()
    }

    // Implement any necessary SFSpeechRecognizerDelegate methods
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle the availability change
    }
}
