//
//  AudioStreamer.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//

import AVFoundation
import Foundation

class AudioStreamer: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var socketManager: SocketIOManager

    init() {
        self.socketManager = SocketIOManager()
        setupRecorder()
    }

    private func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("audio.m4a")

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func startStreaming() {
        print("start streaming")
        socketManager.connect()
        isRecording = true
        audioRecorder?.record()

        // Optionally, you can use a timer or a delegate to periodically send audio data
        // This example does not include the chunking logic
    }

    func stopStreaming() {
        isRecording = false
        audioRecorder?.stop()
        print("stop streaming")
        // Send any remaining audio data here
    }

    func sendAudioChunk() {
        guard let audioURL = audioRecorder?.url else { return }

        do {
            let data = try Data(contentsOf: audioURL)
            print("sending audio chunk")
            socketManager.sendAudioChunk(data)
        } catch {
            print("Error reading audio data: \(error)")
        }
    }
}
