//
//  SplashView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI

struct SplashView: View {
    // Entrance animations (Muncul saat awal)
    @State private var iconScale: CGFloat = 0.5
    @State private var textScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
    // Continuous idle animations (Mengambang terus menerus)
    @State private var isFloating = false
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // 1. Clean Background with Warm Premium Glow (Serasi dengan Pikachu/Emas)
            Color(hex: "#FAFAFA").ignoresSafeArea()
            
            // Soft Radial Glow di tengah (Warna Kuning Pikachu Lembut)
            RadialGradient(
                colors: [Color(hex: "#FFF9C4").opacity(0.7), Color.clear],
                center: .center, startRadius: 0, endRadius: 300
            )
            .blur(radius: 40)
            .ignoresSafeArea()
            // Efek berdenyut lembut pada background
            .scaleEffect(isFloating ? 1.15 : 1.0)
            
            VStack(spacing: 20) {
                
                // 2. THE PREMIUM LOGO ICON (Apple x Pokeball x Pikachu)
                ZStack {
                    // Pulsing Ripple Ring (Energi di belakang logo)
                    Circle()
                        // Menggunakan warna putih/emas lembut untuk ripple
                        .stroke(Color(hex: "#FFD700").opacity(0.5), lineWidth: 5)
                        .frame(width: 170, height: 170)
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                    
                    // ASET GAMBAR IKON LOGO ANDA
                    // Pastikan Anda menaruh bagian "Apel-Pikachu" di Assets dengan nama "app_logo_icon"
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190) // Sesuaikan ukuran
                        // Berikan sedikit bayangan halus agar terlihat 3D di atas background putih
                        .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                        
                        // Animasi Entrance
                        .scaleEffect(iconScale)
                        
                        // Animasi Idle (Mengambang/Berputar sedikit)
                        .rotationEffect(.degrees(isFloating ? 3 : -3))
                        .offset(y: isFloating ? -15 : 0)
                }
                .opacity(contentOpacity)
                
                // 3. THE 3D TYPOGRAPHY (MentorDex)
                VStack(spacing: 12) {
                    // ASET GAMBAR TEKS LOGO ANDA
                    // Pastikan Anda menaruh bagian teks "MentorDex" 3D di Assets dengan nama "app_logo_text"
                    Image("mentordex")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280) // Sesuaikan lebar agar proporsional
                        .shadow(color: Color(hex: "#1A4A6B").opacity(0.1), radius: 10, y: 4) // Bayangan tipis mengikuti warna teks biru
                        .scaleEffect(textScale)
                    
                    // Tagline Original Anda (Dipertahankan karena bagus)
                    Text("Collect the cards. Connect with the mentors.")
                        .font(.custom("Fredoka-SemiBold", size: 14))
                        .foregroundColor(Color(hex: "#888888"))
                        .kerning(1.5)
                        .opacity(isFloating ? 1.0 : 0.7) // Sedikit berkedip lembut
                }
                .opacity(contentOpacity)
                // Typography bergerak sedikit berlawanan arah dengan ikon
                .offset(y: isFloating ? 5 : -5)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: — Animation Logic (Diperbarui untuk Logo Baru)
    private func startAnimations() {
        // 1. The Staggered Entrance (Muncul bergantian: Ikon dulu, baru teks)
        
        // Ikon muncul dengan efek "Pop" Spring yang kuat
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
            iconScale = 1.0
            contentOpacity = 1.0
        }
        
        // Teks muncul sedikit terlambat dengan spring yang lebih lembut
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            textScale = 1.0
        }
        
        // 2. The Continuous Idle Float (Gerakan mengambang terus menerus)
        // Dimulai setelah pop-up selesai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        
        // 3. The Continuous Ripple Pulse (Pulsa energi di belakang ikon)
        // Kita ubah warnanya menjadi emas agar serasi dengan trim logo Anda
        withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)) {
            rippleScale = 1.9
            rippleOpacity = 0.0
        }
    }
}

#Preview {
    SplashView()
}
