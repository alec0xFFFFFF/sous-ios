//
//  HomeView.swift
//  sous
//
//  Created by Alexander K White on 11/26/23.
//

import Foundation
import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            VStack(spacing: 0) {
                RecipeListView()
            }
            .tabItem {
                Image(systemName: "doc.text")
                Text("Browse Recipes")
            }
            CaptureView().tabItem {
                Image(systemName: "square.badge.plus")
                Text("Capture")
            }
            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                    Text("Chat")
                }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor(Color.orange.opacity(0.2))
            
            // Use this appearance when scrolling behind the TabView:
            UITabBar.appearance().standardAppearance = appearance
            // Use this appearance when scrolled all the way up:
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
