//
//  SocketManager.swift
//  sous
//
//  Created by Alexander K White on 2/15/24.
//

import Foundation
import SocketIO

class SocketIOManager: ObservableObject {
    let manager = SocketManager(socketURL: URL(string: "https://recipe-service-production.up.railway.app/")!, config: [.log(true), .compress])
    lazy var socket = manager.defaultSocket
    
    init() {
        socket.connect()
        socket.emit("messageEvent", ["Hello, Server!"]) {
            // ack is an array containing any data sent back by the server in the acknowledgment
            print("Acknowledgment received without msg")
        }
    }

    func connect() {
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }

        socket.on("someEvent") {data, ack in
            guard let cur = data[0] as? Double else { return }
            print("socket event 'someEvent' with data: \(cur)")
        }

        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }
    
    func sendMessage(message: String, onEvent event: String) {
        print("sending the message")
        socket.emit(event, message)
    }
    
    func sendAudioChunk(_ data: Data) {
        print("sending the audio chunk")
        socket.emit("audio_chunk", data)
    }
}
