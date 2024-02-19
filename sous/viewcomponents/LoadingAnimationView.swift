//
//  DotView.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//

import Foundation
import SwiftUI

struct LoadingAnimationView: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                DotView(delay: Double(index) * 0.2)
            }
        }
    }
}

struct DotView: View {
    var delay: Double
    @State private var isAnimating = false
    private let animationDuration: Double = 0.6
    private let dotSize: CGFloat = 10
    private let movementAmount: CGFloat = 15

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: dotSize, height: dotSize)
            .offset(y: isAnimating ? -movementAmount : movementAmount)
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                self.isAnimating.toggle()
            }
    }
}
