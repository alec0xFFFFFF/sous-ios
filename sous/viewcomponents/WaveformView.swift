//
//  WaveformView.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//

import Foundation
import SwiftUI

struct WaveformBar: View {
    var delay: Double
    @State private var isAnimating = false
    @State private var barHeight: CGFloat = 50
    private let animationDuration: Double = 0.2

    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
            .frame(width: 5, height: barHeight)
            .cornerRadius(5)
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
            )
            .onAppear {
                self.isAnimating = true
            }
            .onReceive(Timer.publish(every: animationDuration / 2, on: .main, in: .common).autoconnect()) { _ in
                if isAnimating {
                    barHeight = CGFloat.random(in: 20...65)
                }
            }
    }
}

struct WaveformView: View {
    var body: some View {
        VStack{
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    WaveformBar(delay: Double(index) * 0.05)
                }
                
            }
        }
    }
}
