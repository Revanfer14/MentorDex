//
//  PackOpeningView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI
import SceneKit
import CoreMotion
import Combine

// MARK: - Pack Opening View

struct PackOpeningView: View {
    let tier: ChallengeTier
    let rewardCards: [GameState.RewardCard]

    var dismissAll: (() -> Void)? = nil
    
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss           // dismisses just this screen
    
    @State private var phase: OpeningPhase = .packIdle
    
    // PackLayers states
    @State private var topHalfOffset: CGFloat = 0      // Vertical movement (Y)
    @State private var topHalfXOffset: CGFloat = 0     // Horizontal (X)
    @State private var topHalfRotation: Double = 0     // Slight tilt
    @State private var botHalfOffset: CGFloat = 0
    
    @State private var cardDragOffset: CGFloat = 0
    @State private var tearProgress: CGFloat = 0       // 0→1 driven by drag
    @State private var currentCardIndex = 0
    @State private var shimmerPhase: CGFloat = 0       // 0→1 for foil sweep on pack
    @State private var packWiggle: Double = 0
    @State private var packGlow: Bool = false
    
    enum OpeningPhase { case packIdle, revealing, done }
    
    // Pack image dimensions
    private let packW: CGFloat = 360
    private let packH: CGFloat = 520
    private let tearFraction: CGFloat = 0.45
    
    var body: some View {
        ZStack {
            deepBackground
            EnergyParticles(tier: tier)
            
            switch phase {
            case .packIdle:
                packScene
                    .transition(.identity)
            case .revealing:
                cardRevealScene
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.05).combined(with: .opacity),
                        removal: .opacity
                    ))
            case .done:
                allDoneScene
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            playMusic("musicbukapack", true)
            startIdleAnimations()
        }
        .onDisappear {
            AudioManager.shared.playBGM(filename: "main-bgm")
        }
    }
    
    // MARK: — Premium Sky Background
    
    private var deepBackground: some View {
        ZStack {
            // Main Sky Blue Base
            LinearGradient(
                colors: [Color(hex: "#F2FAFF"), Color(hex: "#D6F0FF")],
                startPoint: .top, endPoint: .bottom
            )
            
            // Soft animated Sun glow behind the pack
            RadialGradient(
                colors: [Color(hex: "#FFF9D2").opacity(packGlow ? 0.9 : 0.4), Color.clear],
                center: .center, startRadius: 0, endRadius: 350
            )
            .scaleEffect(x: 1.3, y: 1.0)
            .offset(y: -40)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: packGlow)
        }
        .ignoresSafeArea()
    }
    
    // MARK: — Pack Scene
    
    private var packScene: some View {
        VStack(spacing: 32) {
            // Instruction label
            Text(tearProgress > 0.1 ? "Let's see what you got..." : "Swipe UP to open!")
                .font(.custom("Fredoka-Bold", size: 26))
                .foregroundColor(Color.textPrimary)
                .shadow(color: .white.opacity(0.8), radius: 10)
                .animation(.easeInOut(duration: 0.2), value: tearProgress > 0.1)
            
            // Pack layers (Now using 3D Model)
            ZStack {
                // ── BOTTOM HALF (3D) ──
                Pack3DView(modelName: "pack_3d_\(tier.rawValue)")
                    .frame(width: packW, height: packH)
                    .clipped()
                    .clipShape(
                        Rectangle()
                            .offset(y: packH * tearFraction)
                            .size(width: packW, height: packH * (1 - tearFraction))
                    )
                    .offset(y: botHalfOffset)
                
                // ── TOP HALF (3D) ──
                Pack3DView(modelName: "pack_3d_\(tier.rawValue)")
                    .frame(width: packW, height: packH)
                    .clipped()
                    .clipShape(
                        Rectangle()
                            .size(width: packW, height: packH * tearFraction)
                    )
                    .offset(x: topHalfXOffset, y: topHalfOffset)
                    .rotationEffect(.degrees(topHalfRotation))
                
                // Foil shimmer strip (Efek kilap tetap dipertahankan di atas 3D)
                if tearProgress < 0.05 {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.35), Color.clear],
                                startPoint: UnitPoint(x: shimmerPhase - 0.15, y: 0),
                                endPoint: UnitPoint(x: shimmerPhase + 0.15, y: 1)
                            )
                        )
                        .frame(width: packW, height: packH)
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
                
                // Drag gesture overlaid
                Color.clear
                    .frame(width: packW, height: packH)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 6)
                            .onChanged { v in
                                playSound("bukapack")
                                let raw = max(0, min(1, -v.translation.height / 200))
                                tearProgress = raw
                                topHalfOffset = -raw * 120
                                topHalfXOffset = raw * 80
                                topHalfRotation = raw * -5
                                botHalfOffset = raw * 40
                            }
                            .onEnded { v in
                                if tearProgress > 0.4 {
                                    finishTear()
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        tearProgress = 0
                                        topHalfOffset = 0
                                        topHalfXOffset = 0
                                        topHalfRotation = 0
                                        botHalfOffset = 0
                                    }
                                }
                            }
                    )
            }
            
            // Chevron hint
            Image(systemName: "chevron.compact.up")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.textSecondary.opacity(tearProgress > 0.1 ? 0 : 0.6))
                .offset(y: packGlow ? -5 : 5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: packGlow)
                .animation(.easeInOut(duration: 0.2), value: tearProgress)
        }
    }
    
    // MARK: — Card Reveal Scene
    
    private var cardRevealScene: some View {
        VStack(spacing: 24) {
            // Progress dots
            HStack(spacing: 10) {
                ForEach(0..<rewardCards.count, id: \.self) { i in
                    Circle()
                        .fill(i <= currentCardIndex ? tier.packColor : Color(hex: "#82BBDD").opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.spring(), value: currentCardIndex)
                }
            }
            
            if currentCardIndex < rewardCards.count {
                SpinningRevealCard(card: rewardCards[currentCardIndex], tier: tier)
                    .id(currentCardIndex)
                    .offset(x: cardDragOffset)
                    .rotationEffect(.degrees(Double(cardDragOffset / 12)))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                cardDragOffset = gesture.translation.width
                            }
                            .onEnded { gesture in
                                if abs(gesture.translation.width) > 100 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        cardDragOffset = gesture.translation.width > 0 ? 500 : -500
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        nextCard()
                                        cardDragOffset = 0
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        cardDragOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.05).combined(with: .opacity),
                        removal: .opacity
                    ))
                
                if currentCardIndex + 1 == rewardCards.count {
                    NextCardButton(
                        label: "Finish! 🎉",
                        color: tier.packColor
                    ) {
                        nextCard()
                    }
                    .padding(.top, 20)
                } else {
                    Text("← Swipe card to continue →")
                        .font(.custom("Fredoka-SemiBold", size: 16))
                        .foregroundColor(Color.textSecondary)
                        .padding(.top, 20)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: currentCardIndex)
    }
    
    // MARK: — All Done Scene
    
    private var allDoneScene: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Text("🎉")
                    .font(.system(size: 80))
                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 20)
                
                Text("Pack Opened!")
                    .font(.custom("Fredoka-Bold", size: 35))
                    .foregroundColor(Color.textPrimary)
                
                Text("Cards added to your gallery")
                    .font(.custom("Fredoka-Regular", size: 18))
                    .foregroundColor(Color.textSecondary)
                
                VStack(spacing: 12) {
                    ForEach(rewardCards) { card in
                        HStack(spacing: 16) {
                            Text(card.grade == .legendary ? "🌟" : (card.grade == .epic ? "⭐" : "📄"))
                                .font(.system(size: 26))
                            Text(card.mentor.name)
                                .font(.custom("Fredoka-Bold", size: 20))
                                .foregroundColor(Color.textPrimary)
                            Spacer()
                            
                            // Grade Tag
                            Text(card.grade.rawValue.uppercased())
                                .font(.custom("Fredoka-Regular", size: 12))
                                .kerning(1.5)
                                .foregroundColor(card.grade == .common ? Color.textPrimary : .white)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(
                                    Capsule().fill(
                                        card.grade == .legendary
                                        ? LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#FCA048"), Color(hex: "#FFD700")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : (card.grade == .epic ? LinearGradient(colors: [Color.epiccard], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color(hex: "#E8F4FA"), Color(hex: "#E8F4FA")], startPoint: .top, endPoint: .bottom))
                                    )
                                )
                                .shadow(color: card.grade == .legendary ? Color(hex: "#FFD700").opacity(0.4) : .clear, radius: 4)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .shadow(color: Color(hex: "#82BBDD").opacity(0.15), radius: 10, y: 5)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: goHome) {
                    Text("View Gallery")
                        .font(.custom("Fredoka-Bold", size: 22))
                        .foregroundColor(.white)
                        .padding(.horizontal, 50).padding(.vertical, 18)
                        .background(Capsule().fill(Color.textSecondary))
                }
                .padding(.top, 16)
            }
            .padding(.top, 60).padding(.bottom, 40)
        }
        .padding(.top, 100)
        .onAppear {
            playSound("dapetkartu")
        }
    }
    
    // MARK: — Logic
    
    private func startIdleAnimations() {
        packGlow = true
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            packWiggle = 1.8
        }
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            shimmerPhase = 1.3
        }
    }
    
    private func finishTear() {
        playHaptic(style: .heavy, intensity: 1.0)
        playSound("bukapack")
        
        AudioManager.shared.stopBGM()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            topHalfOffset = -80
            topHalfXOffset = 600
            topHalfRotation = -15
            
            botHalfOffset = 600
            tearProgress = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .revealing
                currentCardIndex = 0
            }
        }
    }
    
    private func nextCard() {
        if currentCardIndex + 1 < rewardCards.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentCardIndex += 1
            }
        } else {
            withAnimation(.spring()) { phase = .done }
        }
    }
    
    private func goHome() {
        gameState.currentTab = .gallery
        if let dismissAll = dismissAll {
            dismissAll()
        } else {
            dismiss()
        }
    }
}

// MARK: - Energy Particles

struct EnergyParticles: View {
    let tier: ChallengeTier
    @State private var phase: Bool = false
    @State private var positions: [(CGFloat, CGFloat, CGFloat)]
    
    init(tier: ChallengeTier) {
        self.tier = tier
        let initialPositions: [(CGFloat, CGFloat, CGFloat)] = (0..<24).map { i in
            let startX = CGFloat((i * 67 + 31) % 390)
            let startY = CGFloat((i * 113 + 17) % 820)
            let particleSize = CGFloat.random(in: 4...8)
            return (startX, startY, particleSize)
        }
        _positions = State(initialValue: initialPositions)
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                let (x, y, size) = positions[i]
                Circle()
                    .fill(tier.packColor.opacity(phase ? 0.3 : 0.05))
                    .frame(width: size, height: size)
                    .position(x: x, y: phase ? y - 40 : y + 40)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.8...3.2))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: phase
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear { phase = true }
    }
}

// MARK: - Spinning Reveal Card (WITH HOLOGRAM EFFECT)

struct SpinningRevealCard: View {
    let card: GameState.RewardCard
    let tier: ChallengeTier

    @State private var spinDegrees: Double = 0
    @State private var showFront: Bool = false
    @State private var cardScale: CGFloat = 0.35 // Skala awal saat melompat dari bungkus
    @State private var epicBurst: Bool = false
    @State private var floatOffset: CGFloat = 0
    
    @StateObject private var motion = GyroHoloManager()
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Majestic Burst for Epic & Legendary
                if card.grade == .epic || card.grade == .legendary {
                    let isLegend = card.grade == .legendary
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: isLegend
                                    ? [Color(hex: "#FF6B6B"), Color(hex: "#FFD700"), Color(hex: "#42A5F5"), Color(hex: "#FFD700")] // Rainbow Gold
                                    : [Color(hex: "#FFD700"), Color(hex: "#FFF39D"), Color(hex: "#FFD700")], // Standard Gold
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: epicBurst ? (isLegend ? 8 : 4) : 0
                        )
                        .frame(width: epicBurst ? (isLegend ? 400 : 360) : 260, height: epicBurst ? (isLegend ? 400 : 360) : 260)
                        .opacity(epicBurst ? (isLegend ? 1.0 : 0.8) : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.55), value: epicBurst)
                    
                    Circle()
                        .fill(Color(hex: "#FFD700").opacity(epicBurst ? (isLegend ? 0.25 : 0.15) : 0))
                        .frame(width: 340, height: 340)
                        .animation(.easeOut(duration: 0.6), value: epicBurst)
                }
                
                Group {
                    if showFront {
                        // FRONT FACING CARD WITH HOLOGRAM
                        ZStack {
                            MentorCardFront(mentor: card.mentor, grade: card.grade)

                            if card.grade == .legendary {
                                LegendaryHoloOverlay(pitch: motion.pitch, roll: motion.roll)
                            }
                        }
                    } else {
                        CardBackFace()
                    }
                }
               
                // Susutkan kartu menjadi 75% dari ukuran raksasa aslinya (400x550) agar pas di layar iPhone
                .scaleEffect(0.75)
                // Beritahu SwiftUI ruang (bounding box) yang digunakan SETELAH disusutkan
                .frame(width: 400 * 0.75, height: 550 * 0.75)
                
                // Ini adalah animasi rotasi & loncatan dari bungkus
                .scaleEffect(cardScale)
                .rotation3DEffect(
                    .degrees(spinDegrees),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )
                .shadow(
                    color: card.grade == .legendary ? Color(hex: "#FFD700").opacity(0.8) : (card.grade == .epic ? Color(hex: "#FFD700").opacity(0.6) : Color(hex: "#82BBDD").opacity(0.5)),
                    radius: card.grade == .legendary ? 45 : (card.grade == .epic ? 35 : 20),
                    y: 12
                )
            }
            .offset(y: floatOffset)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: floatOffset)
            
            // Grade label
            if showFront {
                HStack(spacing: 8) {
                    Image(systemName: card.grade == .legendary ? "sparkles" : (card.grade == .epic ? "star.fill" : "checkmark.seal.fill"))
                        .foregroundColor(card.grade == .legendary ? Color(hex: "#FCA048") : (card.grade == .epic ? Color(hex: "#FFB800") : Color(hex: "#42A5F5")))
                    
                    Text("\(card.grade.rawValue) card unlocked!")
                        .font(.custom("Fredoka-Bold", size: 18))
                        .foregroundColor(Color.textPrimary)
                }
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Capsule().fill(Color.white.opacity(0.85)))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if card.grade == .legendary { motion.start() }
            startSpin()
        }
        .onDisappear {
            motion.stop()
        }
    }
    
    private func startSpin() {
        let isLegend = card.grade == .legendary
        let spinSpeed = isLegend ? 0.65 : 0.32
        let bounce = isLegend ? 0.75 : 0.58
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            cardScale = 1.0
        }
        
        // Spin to edge
        withAnimation(.easeIn(duration: spinSpeed)) {
            spinDegrees = 90
        }
        
        // Flip to front
        DispatchQueue.main.asyncAfter(deadline: .now() + spinSpeed) {
            showFront = true

            // Boom Haptic!
            if isLegend {
                // Getaran keras dan mantap untuk Legendary
                playSound("dapetlegend")
                playHaptic(style: .heavy, intensity: 1.0)
            } else if card.grade == .epic {
                // Getaran sedang untuk Epic
                playSound("dapetepic")
                playHaptic(style: .heavy, intensity: 1.0)
            } else {
                // Getaran ringan untuk Common
                playSound("dapetcommon")
                playHaptic(style: .light)
            }
        }
        
        // Settle rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + spinSpeed + 0.01) {
            withAnimation(.spring(response: bounce, dampingFraction: 0.58)) {
                spinDegrees = 0
            }
        }
        
        // Epic/Legend Burst
        if card.grade == .epic || card.grade == .legendary {
            DispatchQueue.main.asyncAfter(deadline: .now() + spinSpeed + 0.5) {
                epicBurst = true
                if isLegend { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                        epicBurst.toggle()
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            floatOffset = -10
        }
    }
}

// MARK: - 🌟 Legendary Holo Overlay (CoreMotion Driven)

struct LegendaryHoloOverlay: View {
    let pitch: Double
    let roll: Double
    
    var body: some View {
        GeometryReader { geo in
            // Menghitung offset gradien berdasarkan kemiringan HP
            let xOffset = CGFloat(roll * 2.0)
            let yOffset = CGFloat(pitch * 2.0)
            
            LinearGradient(
                colors: [
                    Color(hex: "#FF6B6B").opacity(0.6), // Red
                    Color(hex: "#FCA048").opacity(0.6), // Orange
                    Color(hex: "#FFD700").opacity(0.8), // Gold/Yellow
                    Color(hex: "#42A5F5").opacity(0.6), // Blue
                    Color(hex: "#D4B8FF").opacity(0.6), // Purple
                    Color(hex: "#FF6B6B").opacity(0.6)  // Red
                ],
                startPoint: UnitPoint(x: 0.0 + xOffset, y: 0.0 + yOffset),
                endPoint: UnitPoint(x: 1.5 + xOffset, y: 1.5 + yOffset)
            )
            .blendMode(.colorDodge) // Membuat kilau pelangi menyatu dengan warna kartu di bawahnya
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .allowsHitTesting(false)
        }
    }
}

// MARK: - 🌟 CoreMotion Manager

class GyroHoloManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    func start() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/60 // 60 FPS update
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                self?.pitch = data.attitude.pitch
                self?.roll = data.attitude.roll
            }
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Premium Card Back Face

struct CardBackFace: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(
                colors: [Color.white, Color(hex: "#E8F4FA")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "#D6F0FF"), lineWidth: 4)
            )
            .overlay(
                VStack(spacing: 12) {
                    Text("☀️").font(.system(size: 72))
                        .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 10, y: 5)
                    Text("MentorDex")
                        .font(.custom("Fredoka-Bold", size: 18))
                        .kerning(5)
                        .foregroundColor(Color.textSecondary)
                }
            )
    }
}

// MARK: - Next Card Button

struct NextCardButton: View {
    let label: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pressed = false }
            action()
        }) {
            Text(label)
                .font(.custom("Fredoka-Bold", size: 22))
                .foregroundColor(.white)
                .padding(.horizontal, 48).padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 15, y: 6)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.93 : 1.0)
        .animation(.spring(), value: pressed)
    }
}

// MARK: - AnyShape helper

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { _path = shape.path(in:) }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

// MARK: - Pack3DView

struct Pack3DView: UIViewRepresentable {
    let modelName: String
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero, options: nil)
        
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        
        if let sceneURL = Bundle.main.url(forResource: modelName, withExtension: "usdz"),
           let sceneSource = SCNSceneSource(url: sceneURL, options: nil),
           let scene = try? sceneSource.scene(options: nil) {
            
            scene.background.contents = UIColor.clear
            
            scene.rootNode.enumerateHierarchy { (node, _) in
                if let geometry = node.geometry {
                    for material in geometry.materials {
                        material.transparencyMode = .aOne
                        material.blendMode = .alpha
                        material.writesToDepthBuffer = true
                    }
                }
            }
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light?.type = .ambient
            ambientLightNode.light?.color = UIColor(white: 0.85, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLightNode)
            
            let omniLightNode = SCNNode()
            omniLightNode.light = SCNLight()
            omniLightNode.light?.type = .omni
            omniLightNode.light?.color = UIColor(white: 0.7, alpha: 1.0)
            omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            scene.rootNode.addChildNode(omniLightNode)
            
            let frontLightNode = SCNNode()
            frontLightNode.light = SCNLight()
            frontLightNode.light?.type = .directional
            frontLightNode.light?.color = UIColor(white: 0.9, alpha: 1.0)
            frontLightNode.position = SCNVector3(x: 0, y: 0, z: 10)
            scene.rootNode.addChildNode(frontLightNode)
            
            let scaleSize: Float = 0.85
            scene.rootNode.scale = SCNVector3(scaleSize, scaleSize, scaleSize)
            
            let spinAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 12)
            let repeatSpin = SCNAction.repeatForever(spinAction)
            scene.rootNode.runAction(repeatSpin)
            
            scnView.scene = scene
        }
        
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
