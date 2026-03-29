//
//  DashboardView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedTier: ChallengeTier? = nil
    @ObservedObject private var audioManager = AudioManager.shared
    
    @State private var showStashOpening = false
    @State private var stashTierToOpen: ChallengeTier? = nil
    @State private var stashRewardCards: [GameState.RewardCard] = []

    @State private var showDisclaimer: Bool = false
    static var hasSeenDisclaimer: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#D6F0FF"), Color(hex: "#F2FAFF")],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                RadialGradient(
                    colors: [Color(hex: "#FFF9D2").opacity(0.6), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 350
                )
                .blur(radius: 40)
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        headerSection
                        
                        unopenedPacksSection
                        
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Choose Your Pack")
                                .font(.custom("Fredoka-Bold", size: 24))
                                .foregroundColor(Color.textPrimary)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(ChallengeTier.allCases) { tier in
                                        PackCard(tier: tier) {
                                            selectedTier = tier
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
                        
                        quickStats
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 12)
                }
                
                if showDisclaimer {
                    ZStack {
                        // Latar belakang gelap transparan
                        Color.black.opacity(0.6)
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                        
                        // Kotak Pop-up
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.propack)
                                    .shadow(color: Color(hex: "#F59E0B").opacity(0.4), radius: 10, y: 5)
                                
                                Text("DISCLAIMER")
                                    .font(.custom("Fredoka-Bold", size: 24))
                                    .foregroundColor(Color.textPrimary)
                            }
                            
                            // Isi Disclaimer
                            VStack(alignment: .leading, spacing: 16) {
                                DisclaimerRow(
                                    number: "1",
                                    text: "All mentors at the Apple Developer Academy have 3 card variations: Common, Epic, and Legendary."
                                )
                                
                                DisclaimerRow(
                                    number: "2",
                                    text: "The Common, Epic, and Legendary tiers purely represent in-game card rarity and are NOT intended to evaluate or rank the mentors' real-life performance."
                                )
                            }
                            .padding(.vertical, 8)
                            
                            // Tombol Mengerti
                            Button(action: {
                                playHaptic(style: .medium)
                                playSound("click")
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showDisclaimer = false
                                }
                            }) {
                                Text("I Understand")
                                    .font(.custom("Fredoka-Bold", size: 20))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        Capsule()
                                            .fill(Color.textSecondary)
                                    )
                            }
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 30, y: 15)
                        )
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                    }
                    .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedTier) { tier in
                PathSelectionSheet(tier: tier)
                    .presentationDetents([.fraction(0.55)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
            }
            .fullScreenCover(isPresented: $showStashOpening) {
                if let tier = stashTierToOpen {
                    PackOpeningView(tier: tier, rewardCards: stashRewardCards) {
                        showStashOpening = false
                    }
                    .environmentObject(gameState)
                }
            }
            .onAppear {
                if !Self.hasSeenDisclaimer{
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            showDisclaimer = true
                                            playHaptic(style: .heavy)
                                        }
                                    }
                                    // Tandai bahwa user sudah melihatnya di sesi ini
                                    Self.hasSeenDisclaimer = true
                                }
            }
        }
    }
    
    // MARK: — Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Button {
                    playHaptic(style: .light)
                    playSound("click")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showDisclaimer = true
                    }
                } label: {
                    Image("textrata")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100) // Sesuaikan angkanya jika logonya kurang besar atau terlalu besar
                        .shadow(color: Color(hex: "#1A4A6B").opacity(0.1), radius: 5, y: 2) // Tambahan shadow tipis agar makin 3D
                }
            }
            
            Spacer()
            
            Button(action: {
                AudioManager.shared.toggleMusic()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                    
                        .shadow(color: Color(hex: "#90C2E7").opacity(0.3), radius: 10, y: 5)
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(audioManager.isMuted ? Color.gray.opacity(0.5) : Color.textPrimary)
                }
            }
        }
        .padding(.horizontal, 24)
//        .padding(.top, 5)
        
        .onAppear {
            AudioManager.shared.startBackgroundMusic(filename: "main-bgm")
        }
    }
    
    // Unopened Pack Section
    @ViewBuilder
    private var unopenedPacksSection: some View {
        
        let stashedTiers = ChallengeTier.allCases.filter { tier in
            gameState.unopenedPacks.contains(tier)
        }
        
        if !stashedTiers.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Inventory")
                        .font(.custom("Fredoka-Bold", size: 24))
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    Text("\(gameState.unopenedPacks.count) \(gameState.unopenedPacks.count > 1 ? "Packs" : "Pack")")
                        .font(.custom("Fredoka-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Color.textPrimary))
                }
                .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(stashedTiers) { tier in
                            let count = gameState.unopenedPacks.filter { $0 == tier }.count
                            StashPackCard(tier: tier, count: count) {
                                openStashedPack(tier: tier)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 15)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Inventory")
                        .font(.custom("Fredoka-Bold", size: 24))
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    Text("\(gameState.unopenedPacks.count) \(gameState.unopenedPacks.count > 1 ? "Packs" : "Pack")")
                        .font(.custom("Fredoka-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "#FF6B6B")))
                }
                .padding(.horizontal, 24)
                
                Text("You have no pack in your inventory")
                    .font(.custom("Fredoka-SemiBold", size: 14))
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 15)
        }
    }
    
    // Logika membuka Pack dari Stash
    private func openStashedPack(tier: ChallengeTier) {
        // 1. Hapus 1 pack dari inventory
        if let index = gameState.unopenedPacks.firstIndex(of: tier) {
            gameState.unopenedPacks.remove(at: index)
            gameState.saveState()
        }
        
        // 2. Generate kartu menggunakan probabilitas standar (tanpa perfect run bonus)
        stashRewardCards = gameState.distributeRewards(tier: tier)
        stashTierToOpen = tier
        
        // 3. Tampilkan animasi 3D Unboxing
        showStashOpening = true
    }
    
    struct StashPackCard: View {
        let tier: ChallengeTier
        let count: Int
        let action: () -> Void
        
        @State private var pressed = false
        
        var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pressed = false
                    action()
                }
            }) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 12) {
                        Image("pack_preview_\(tier.rawValue)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 100)
                            .shadow(color: Color.textPrimary.opacity(0.15), radius: 10, y: 8)
                        
                        VStack(spacing: 4) {
                            Text(tier.packLabel)
                                .font(.custom("Fredoka-Bold", size: 14))
                                .foregroundColor(Color.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("Tap to Open")
                                .font(.custom("Fredoka-Regular", size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    .frame(width: 140, height: 170)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .shadow(color: Color(hex: "#82BBDD").opacity(0.2), radius: 15, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(tier.packColor.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    
                    if count > 1 {
                        Text("x\(count)")
                            .font(.custom("Fredoka-Bold", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#FF4757"))
                                    .shadow(color: Color(hex: "#FF4757").opacity(0.4), radius: 4, y: 2)
                            )
                            .offset(x: 10, y: -5)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(pressed ? 0.9 : 1.0)
            .animation(.spring(), value: pressed)
        }
    }
    
    // MARK: — Quick Stats
    
    private var quickStats: some View {
        VStack(alignment: .leading) {
            Text("Card Status")
                .font(.custom("Fredoka-Bold", size: 24))
                .foregroundColor(Color.textPrimary)
            
            HStack(spacing: 14) {
                StatPill(
                    emoji: "🌟",
                    label: "Legendary",
                    value: "\(gameState.gallery.filter { $0.isUnlocked && $0.grade == .legendary }.count)"
                )
                StatPill(
                    emoji: "🥇",
                    label: "Epic",
                    value: "\(gameState.gallery.filter { $0.isUnlocked && $0.grade == .epic }.count)"
                )
                StatPill(
                    emoji: "📦",
                    label: "Common",
                    value: "\(gameState.gallery.filter { $0.isUnlocked && $0.grade == .common }.count)"
                )
                StatPill(
                    emoji: "🔒",
                    label: "Locked",
                    value: "\(gameState.gallery.filter { !$0.isUnlocked }.count)"
                )
            }
        }
        .padding(.horizontal, 24)
        
    }
}

// MARK: - Premium Pack Card

struct PackCard: View {
    let tier: ChallengeTier
    let onTap: () -> Void
    
    @State private var pressed = false
    @State private var isBouncing = false
    
    var body: some View {
        Button(action: {
            playSound("click")
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                pressed = false
                onTap()
            }
        }) {
            VStack(spacing: 16) {
                
                Text("TIER \(tier.rawValue)")
                    .font(.custom("Fredoka-Bold", size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(tier.packColor))
                    .shadow(color: tier.packColor.opacity(0.5), radius: 4, y: 2)
                
                
                ZStack(alignment: .topLeading) {
                    
                    Image("pack_preview_\(tier.rawValue)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 380, height: 200)
                        .offset(y: isBouncing ? -12 : 0)
                        .scaleEffect(isBouncing ? 1.05 : 1.0)
                        .shadow(color: Color.textPrimary.opacity(0.15), radius: 10, y: isBouncing ? 15 : 8)
                    
                    //
                        .task {
                            try? await Task.sleep(nanoseconds: UInt64(tier.rawValue) * 300_000_000)
                            
                            while !Task.isCancelled {
                                // Fase 1: Melompat ke atas
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isBouncing = true
                                }
                                
                                try? await Task.sleep(nanoseconds: 200_000_000) // Tahan di atas selama 0.2 detik
                                
                                // Fase 2: Mendarat kembali
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                    isBouncing = false
                                }
                                
                                // Fase 3: Diam selama 1.8 detik sebelum mengulang (Total siklus 2 detik)
                                try? await Task.sleep(nanoseconds: 3_500_000_000)
                            }
                        }
                }
                .frame(width: 200, height: 190)
                
                VStack(spacing: 4) {
                    Text(tier.packLabel)
                        .font(.custom("Fredoka-Bold", size: 18))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("\(tier.cardRewardCount) Card\(tier.cardRewardCount > 1 ? "s" : "")")
                        .font(.custom("Fredoka-Regular", size: 14))
                        .foregroundColor(Color(hex: "#6BA3C8"))
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: pressed)
    }
}

// MARK: - Premium Stat Pill

struct StatPill: View {
    let emoji: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 26))
                .padding(.bottom, 2)
            Text(value)
                .font(.custom("Fredoka-Bold", size: 22))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(.custom("Fredoka-Regular", size: 13))
                .foregroundColor(Color(hex: "#6BA3C8"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color(hex: "#82BBDD").opacity(0.25), radius: 15, y: 8)
        )
    }
}

// MARK: - Redesigned Path Selection Sheet

struct PathSelectionSheet: View {
    let tier: ChallengeTier
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    
    @State private var showBrain = false
    
    var body: some View {
        ZStack {
            // Very pale blue background for the sheet
            Color(hex: "#F2FAFF").ignoresSafeArea()
            
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text(tier.packLabel)
                        .font(.custom("Fredoka-Bold", size: 28))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(tier.chances)
                        .font(.custom("Fredoka-SemiBold", size: 18))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    
                    
                    Text("\(tier.criteria)")
                        .font(.custom("Fredoka-Regular", size: 17))
                        .foregroundColor(Color.textSecondary)
                }
                .padding(.top, 40)
                
                HStack(spacing: 16) {
                    PathButton(
                        emoji: "🧠",
                        title: "Trivia Quiz",
                        subtitle: "\(tier.description) Quiz",
                        color: Color(hex: "#9C27B0") // Vibrant purple
                    ) { showBrain = true }
                    
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showBrain) {
            BrainChallengeView(tier: tier, dismissAll: {
                showBrain = false
                dismiss()
            })
            .environmentObject(gameState)
            .presentationDetents([.large])
            .presentationCornerRadius(36)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
    }
}

struct PathButton: View {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressed = false
                action()
            }
        }) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 48))
                
                Text(title)
                    .font(.custom("Fredoka-Bold", size: 22))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.custom("Fredoka-Regular", size: 14))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .shadow(color: color.opacity(0.15), radius: 20, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(color.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}

// MARK: - Disclaimer Row Component
struct DisclaimerRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Lingkaran Angka
            Text(number)
                .font(.custom("Fredoka-Bold", size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "#82BBDD")))
            
            // Teks Penjelasan
            Text(text)
                .font(.custom("Fredoka-Regular", size: 15))
                .foregroundColor(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
