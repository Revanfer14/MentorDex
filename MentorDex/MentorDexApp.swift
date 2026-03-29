//
//  MentorDexApp.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI

@main
struct MentorDexApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
        }
    }
}

// MARK: - Root View (handles Splash → Main)

struct RootView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showSplash = false
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        TabView(selection: $gameState.currentTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.dashboard)
            
            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.gallery)
        }
        .tint(Color(hex: "#1A4A6B"))
        .fontDesign(.rounded)
        .onChange(of: gameState.currentTab) {
            playSound("click")
            playHaptic(style: .heavy, intensity: 1.0)
        }
    }
}
