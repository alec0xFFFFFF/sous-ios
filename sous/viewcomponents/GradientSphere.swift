//
//  GradientSphere.swift
//  sous
//
//  Created by Alexander K White on 2/18/24.
//

import Foundation
import SwiftUI


struct GradientSphere: View {
    @Binding var isSpeaking: Bool
    @Binding var isThinking: Bool
    @State private var gradientCenter = UnitPoint(x: 0.5, y: 0.5)
    
    @State private var scale: CGFloat = 1.0

    var body: some View {
        let colors: [Color] = isSpeaking ? [.red, .orange] : isThinking ? [.green, .yellow] : [.purple, .blue]
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


