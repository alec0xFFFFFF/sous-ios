//
//  BrowseView.swift
//  sous
//
//  Created by Alexander K White on 11/25/23.
//

import SwiftUI


struct BrowseView: View {
    let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 111.0 / 255.0, green: 137.0 / 255.0, blue: 135.0 / 255.0), Color(red: 0.62, green: 0.76, blue: 0.76), Color(red: 197.0 / 255.0, green: 219.0 / 255.0, blue: 218.0 / 255.0)]),
        startPoint: .top,
        endPoint: .bottom
    )
    // todo get request  for what user  has logged
    // tiles of images
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    ForEach(0 ..< 15) { item in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange)
                            .frame(height: 44)
                            .padding()
                    }
                }
            }.navigationTitle("Browse")
        }
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
    }
}
