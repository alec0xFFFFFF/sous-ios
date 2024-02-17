//
//  SpeechBuffer.swift
//  sous
//
//  Created by Alexander K White on 2/16/24.
//

import AVFoundation

class SpeechBufferer {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let synthesizer = AVSpeechSynthesizer()
    private var outputFile: AVAudioFile?

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let format = mixer.outputFormat(forBus: 0)
        engine.attach(mixer)
        engine.connect(engine.inputNode, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Audio Engine didn't start: \(error)")
        }
    }

    func bufferSpeech(from text: String, to fileURL: URL) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        do {
            let format = mixer.outputFormat(forBus: 0)
            outputFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
            mixer.installTap(onBus: 0, bufferSize: 4096, format: format) { (buffer, _) in
                do {
                    try self.outputFile?.write(from: buffer)
                } catch {
                    print("Error writing buffer to file: \(error)")
                }
            }
        } catch {
            print("Error creating audio file: \(error)")
        }

        synthesizer.write(utterance) { buffer in
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
//            self.mixer.renderBlock(pcmBuffer)
//            if buffer.isFinal {
//                self.engine.stop()
//                self.mixer.removeTap(onBus: 0)
//                self.outputFile = nil
//            }
        }
    }
}
