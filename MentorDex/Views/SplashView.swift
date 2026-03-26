// SplashView.swift
// MentorDex — Splash / Launch Screen

import SwiftUI

struct SplashView: View {
    // Entrance animations
    @State private var appearScale: CGFloat = 0.01
    @State private var appearOpacity: Double = 0
    
    // Continuous idle animations
    @State private var isFloating = false
    @State private var rippleScale: CGFloat = 0.8
    @State private var rippleOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // 1. Clean Background with Soft Radial Glow
            Color(hex: "#FAFAFA").ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "#FFF39D").opacity(0.6))
                .blur(radius: 80)
                .frame(width: 350, height: 350)
                .scaleEffect(isFloating ? 1.1 : 0.9)
                .offset(y: -40)
            
            VStack(spacing: 40) {
                
                // 2. The Overlapping Booster Packs Icon
                ZStack {
                    // Pulsing Ripple Ring
                    Circle()
                        .stroke(Color(hex: "#FFD700").opacity(0.4), lineWidth: 6)
                        .frame(width: 160, height: 160)
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                    
                    // Back Pack (Airy Blue)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#A7E2FF"), Color(hex: "#7AC5EE")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 160)
                        .rotationEffect(.degrees(isFloating ? -12 : -6))
                        .offset(x: -25, y: isFloating ? -8 : 0)
                        .shadow(color: Color(hex: "#A7E2FF").opacity(0.4), radius: 15, y: 8)
                    
                    // Front Pack (Sunshine Yellow)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD700")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 175)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                        )
                        .overlay(
                            Text("☀️")
                                .font(.system(size: 64))
                                .shadow(color: Color(hex: "#FFB800").opacity(0.5), radius: 10, y: 5)
                        )
                        .rotationEffect(.degrees(isFloating ? 6 : 2))
                        .offset(x: 10, y: isFloating ? -15 : 0)
                        .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 25, y: 12)
                }
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                
                // 3. Typography
                VStack(spacing: 8) {
                    Text("MentorDex")
                        .font(.custom("Fredoka-Bold", size: 46))
                        .foregroundColor(Color(hex: "#1A4A6B"))
                        .shadow(color: Color(hex: "#1A4A6B").opacity(0.15), radius: 10, y: 4)
                    
                    Text("Collect the cards. Connect with the mentors.")
                        .font(.custom("Fredoka-SemiBold", size: 14))
                        .foregroundColor(Color(hex: "#888888"))
                        .kerning(1.5)
                }
                .scaleEffect(appearScale)
                .opacity(appearOpacity)
                .offset(y: isFloating ? 0 : 5)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: — Animation Logic
    private func startAnimations() {
        // 1. The Entrance "Pop"
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            appearScale = 1.0
            appearOpacity = 1.0
        }
        
        // 2. The Continuous Idle Float (Starts slightly after the pop)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        
        // 3. The Continuous Ripple Pulse
        withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
            rippleScale = 1.8
            rippleOpacity = 0.0
        }
    }
}

#Preview {
    SplashView()
}
