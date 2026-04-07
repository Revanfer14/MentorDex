//
//  DashboardView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI
import TipKit

struct DashboardView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var audioManager = AudioManager.shared
    
    // State untuk Toko & Kuis
    @State private var showQuiz = false
    
    // State untuk Buka Pack (Dari Shop maupun Inventory)
    @State private var showPackOpening = false
    @State private var activeTier: ChallengeTier? = nil
    @State private var activeCards: [GameState.RewardCard] = []
    
    @State private var showDisclaimer: Bool = false
    static var hasSeenDisclaimer: Bool = false
    
    // NState untuk Pop-up Konfirmasi
    @State private var showQuizConfirmation = false
    @State private var showPurchaseConfirmation = false
    @State private var pendingPurchaseTier: ChallengeTier? = nil
    @State private var pendingPurchasePrice: Int = 0
    
    let quizTip = QuizTip()
    let shopTip = ShopTip()
    let inventoryTip = InventoryTip()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#D6F0FF"), Color(hex: "#F2FAFF")],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
                
                RadialGradient(
                    colors: [Color(hex: "#FFF9D2").opacity(0.6), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 350
                ).blur(radius: 40).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        headerSection
                        
                        playQuizSection
                        
                        shopSection
                        
                        unopenedPacksSection
                        
                        Spacer()
                    }
                    .padding(.top, 12)
                }
                
                if showDisclaimer { disclaimerOverlay }
                if showQuizConfirmation { quizConfirmationOverlay }
                if showPurchaseConfirmation { purchaseConfirmationOverlay }
            }
            .navigationBarHidden(true)
            
            .toolbar(showDisclaimer || showQuizConfirmation || showPurchaseConfirmation ? .hidden : .visible, for: .tabBar)
            
            // Trigger Kuis
            .fullScreenCover(isPresented: $showQuiz) {
                BrainChallengeView()
                    .environmentObject(gameState)
            }
            
            // Trigger Buka Pack
            .fullScreenCover(isPresented: $showPackOpening) {
                if let tier = activeTier {
                    PackOpeningView(tier: tier, rewardCards: activeCards) {
                        showPackOpening = false
                    }
                    .environmentObject(gameState)
                }
            }
            
            .onAppear {
                if !Self.hasSeenDisclaimer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showDisclaimer = true
                            playHaptic(style: .heavy)
                        }
                    }
                    Self.hasSeenDisclaimer = true
                }
                AudioManager.shared.startBackgroundMusic(filename: "main-bgm")
            }
        }
    }
    
    // MARK: — Header & Coin UI
    private var headerSection: some View {
        HStack {
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
                    .frame(height: 100)
                    .shadow(color: Color(hex: "#1A4A6B").opacity(0.1), radius: 5, y: 2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .font(.system(size: 20))
                    
                    Text("\(gameState.coins)")
                        .font(.custom("Fredoka-Bold", size: 18))
                        .foregroundColor(Color.textPrimary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 5, y: 2))
                
                Button(action: {
                    AudioManager.shared.toggleMusic()
                    playHaptic(style: .light)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color(hex: "#90C2E7").opacity(0.3), radius: 5, y: 2)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(audioManager.isMuted ? .gray : Color.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: — Play Quiz Section
    private var playQuizSection: some View {
        Button(action: {
            playSound("click")
            playHaptic(style: .medium)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showQuizConfirmation = true
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#D6F0FF"))
                        .frame(width: 56, height: 56)
                    Text("🧠")
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Play Trivia Quiz")
                        .font(.custom("Fredoka-Bold", size: 20))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Earn coins to buy packs!")
                        .font(.custom("Fredoka-Regular", size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#82BBDD"))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "#82BBDD").opacity(0.2), radius: 15, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(hex: "#D6F0FF"), lineWidth: 2)
            )
            .padding(.horizontal, 24)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
        .popoverTip(QuizTip(), arrowEdge: .top) { action in
            if action.id == "next" {
                quizTip.invalidate(reason: .actionPerformed)
                ShopTip.isQuizTipDone = true
            }
        }
    }
    
    // MARK: — Shop Section
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Pack Shop")
                    .font(.custom("Fredoka-Bold", size: 24))
                    .foregroundColor(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(ChallengeTier.allCases) { tier in
                        ShopCard(tier: tier, price: getPrice(for: tier)) {
                            promptPurchase(tier: tier, price: getPrice(for: tier))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .popoverTip(ShopTip(), arrowEdge: .bottom) { action in
                    if action.id == "next" {
                        shopTip.invalidate(reason: .actionPerformed)
                        InventoryTip.isShopTipDone = true
                    }
                }
            }
        }
    }
    
    private func getPrice(for tier: ChallengeTier) -> Int {
        switch tier {
        case .tier1: return tier.packPrice
        case .tier2: return tier.packPrice
        case .tier3: return tier.packPrice
        }
    }
    
    private func promptPurchase(tier: ChallengeTier, price: Int) {
        playSound("click")
        playHaptic(style: .medium)
        pendingPurchaseTier = tier
        pendingPurchasePrice = price
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showPurchaseConfirmation = true
        }
    }
    
    private func buyPack() {
        playSound("click")
        guard let tier = pendingPurchaseTier else { return }
        let price = pendingPurchasePrice
        
        withAnimation {
            showPurchaseConfirmation = false
        }
        
        let isSuccess = gameState.spendCoins(price)
        
        if isSuccess {
            playSound("cashregister")
            playHaptic(style: .heavy)
            
            gameState.savePackToInventory(tier: tier)
        } else {
            playSound("insufficient")
            playHaptic(style: .heavy)

        }
    }
    
    // MARK: — Unopened Pack Section (Inventory)
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
                .popoverTip(InventoryTip(), arrowEdge: .top) { action in
                    if action.id == "next" {
                        inventoryTip.invalidate(reason: .actionPerformed)
                    }
                }
                
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
                    
                    Text("0 Pack")
                        .font(.custom("Fredoka-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "#FF6B6B")))
                }
                .padding(.horizontal, 24)
                .popoverTip(InventoryTip(), arrowEdge: .top) { action in
                    if action.id == "next" {
                        inventoryTip.invalidate(reason: .actionPerformed)
                    }
                }
                
                Text("You have no packs in your inventory.")
                    .font(.custom("Fredoka-SemiBold", size: 14))
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private func openStashedPack(tier: ChallengeTier) {
        gameState.removePackFromInventory(tier: tier)
        activeCards = gameState.openPack(tier: tier)
        activeTier = tier
        showPackOpening = true
    }
    
    private var quizConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).background(.ultraThinMaterial).ignoresSafeArea()
                .onTapGesture { withAnimation { showQuizConfirmation = false } } // Bisa ditutup dengan tap di luar
            
            VStack(spacing: 24) {
                Text("🧠")
                    .font(.system(size: 60))
                    .shadow(color: Color(hex: "#42A5F5").opacity(0.4), radius: 10, y: 5)
                
                VStack(spacing: 8) {
                    Text("Ready to Play?")
                        .font(.custom("Fredoka-Bold", size: 26))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Answer 5 trivia questions correctly to earn up to 15 Coins! Ready to test your knowledge?")
                        .font(.custom("Fredoka-Regular", size: 16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        playSound("click")
                        withAnimation { showQuizConfirmation = false }
                    }) {
                        Text("Cancel")
                            .font(.custom("Fredoka-Bold", size: 18))
                            .foregroundColor(Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color(hex: "#F3F4F6")))
                    }
                    
                    Button(action: {
                        playSound("click")
                        withAnimation { showQuizConfirmation = false }
                        // Beri jeda kecil agar animasi pop-up selesai sebelum layar kuis muncul
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showQuiz = true
                        }
                    }) {
                        Text("Start Quiz")
                            .font(.custom("Fredoka-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color(hex: "#A7E2FF")))
                    }
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 32).fill(Color.white).shadow(color: Color.black.opacity(0.2), radius: 30, y: 15))
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .zIndex(101) // Pastikan selalu di atas
    }
    
    // MARK: — PURCHASE CONFIRMATION OVERLAY
    private var purchaseConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).background(.ultraThinMaterial).ignoresSafeArea()
                .onTapGesture { withAnimation { showPurchaseConfirmation = false } }
            
            VStack(spacing: 24) {
                if let tier = pendingPurchaseTier {
                    Image("pack_preview_\(tier.rawValue)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .shadow(color: Color.textPrimary.opacity(0.2), radius: 10, y: 5)
                    
                    VStack(spacing: 8) {
                        Text("Buy \(tier.packLabel)?")
                            .font(.custom("Fredoka-Bold", size: 24))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("This will cost \(pendingPurchasePrice) Coins. The pack will be added to your Inventory.")
                            .font(.custom("Fredoka-Regular", size: 16))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            playSound("click")
                            withAnimation { showPurchaseConfirmation = false }
                        }) {
                            Text("Cancel")
                                .font(.custom("Fredoka-Bold", size: 18))
                                .foregroundColor(Color.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(Color(hex: "#F3F4F6")))
                        }
                        
                        Button(action: {
                            buyPack()
                        }) {
                            HStack(spacing: 6) {
                                Text("Pay")
                                Image(systemName: "bitcoinsign.circle.fill")
                                Text("\(pendingPurchasePrice)")
                            }
                            .font(.custom("Fredoka-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(tier.packColor).shadow(color: tier.packColor.opacity(0.4), radius: 8, y: 4))
                        }
                    }
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 32).fill(Color.white).shadow(color: Color.black.opacity(0.2), radius: 30, y: 15))
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .zIndex(102)
    }
    
    // MARK: — Disclaimer Overlay
    private var disclaimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).background(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.propack)
                        .shadow(color: Color(hex: "#F59E0B").opacity(0.4), radius: 10, y: 5)
                    
                    Text("DISCLAIMER")
                        .font(.custom("Fredoka-Bold", size: 24))
                        .foregroundColor(Color.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerRow(number: "1", text: "All mentors at the Apple Developer Academy have 3 card variations: Common, Epic, and Legendary.")
                    DisclaimerRow(number: "2", text: "The Common, Epic, and Legendary tiers purely represent in-game card rarity and are NOT intended to evaluate or rank the mentors' real-life performance.")
                }
                .padding(.vertical, 8)
                
                Button(action: {
                    playHaptic(style: .medium)
                    playSound("click")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showDisclaimer = false }
                    
                    QuizTip.isDisclaimerClosed = true
                }) {
                    Text("I Understand")
                        .font(.custom("Fredoka-Bold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.textSecondary))
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 32).fill(Color.white).shadow(color: Color.black.opacity(0.2), radius: 30, y: 15))
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
        }
        .zIndex(100)
    }
}

// MARK: - Shop Card
struct ShopCard: View {
    
    let tier: ChallengeTier
    let price: Int
    let onTap: () -> Void
    
    @State private var pressed = false
    @State private var isBouncing = false
    
    var body: some View {
        Button(action: {
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
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                        Text("\(price)")
                    }
                    .font(.custom("Fredoka-Bold", size: 12))
                    .foregroundColor(.yellow)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: pressed)
    }
}

// MARK: - Stash Pack Card (Inventory)
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
                )
                
                if count > 1 {
                    Text("x\(count)")
                        .font(.custom("Fredoka-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#FF4757")).shadow(color: Color(hex: "#FF4757").opacity(0.4), radius: 4, y: 2))
                        .offset(x: 10, y: -5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.9 : 1.0)
    }
}

// MARK: - Disclaimer Row
struct DisclaimerRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.custom("Fredoka-Bold", size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "#82BBDD")))
            
            Text(text)
                .font(.custom("Fredoka-Regular", size: 15))
                .foregroundColor(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
