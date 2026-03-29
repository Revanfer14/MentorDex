//
//  MentorCardFront.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI
import CoreMotion
import Combine

struct MentorCardFront: View {
    let mentor: Mentor
    let grade: CardGrade

    // Gyroscope for Epic & Legendary
    @StateObject private var motionManager = CardMotionManager()

    private var isEpic: Bool { grade == .epic }
    private var isLegendary: Bool { grade == .legendary }
    private var isRare: Bool { isEpic || isLegendary }
    
    // Warna teks dan UI jurus berdasarkan grade (Biru, Ungu, Emas)
    private var gradeMovesTextColor: Color {
        if isLegendary { return Color(hex: "#FFD700") } // Gold-Orange
        if isEpic { return Color(hex: "#9C27B0") } // Purple
        return Color(hex: "#42A5F5") // Blue for Common
    }

    var body: some View {
        ZStack {
            // 1. Card background plate
            RoundedRectangle(cornerRadius: 36)
                .fill(cardBgPlate)

            // 2. Rare/Legendary Holographic Shimmer (Gyro Driven)
            if isRare {
                RoundedRectangle(cornerRadius: 36)
                    .fill(
                        LinearGradient(
                            colors: isLegendary ? [
                                Color(hex: "#FF6B6B").opacity(0.4), // Red
                                Color(hex: "#FFD700").opacity(0.6), // Gold
                                Color(hex: "#42A5F5").opacity(0.4), // Blue
                                Color(hex: "#D4B8FF").opacity(0.5)  // Purple
                            ] : [
                                Color(hex: "#FFF39D").opacity(0.3),
                                Color.white.opacity(0.05),
                                Color(hex: "#A7E2FF").opacity(0.2),
                                Color.white.opacity(0.05),
                                Color(hex: "#D4B8FF").opacity(0.25)
                            ],
                            startPoint: UnitPoint(
                                x: 0.5 + motionManager.tiltX * 0.8,
                                y: 0.5 + motionManager.tiltY * 0.8
                            ),
                            endPoint: UnitPoint(
                                x: 0.5 - motionManager.tiltX * 0.8,
                                y: 0.5 - motionManager.tiltY * 0.8
                            )
                        )
                    )
                    .blendMode(isLegendary ? .colorDodge : .overlay)
            }

            // 3. Card border
            RoundedRectangle(cornerRadius: 36)
                .stroke(borderGradient, lineWidth: isLegendary ? 4 : (isEpic ? 3 : 2))

            // 4. Pokémon-style Detailed Content
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mentor.nickname)
                            .font(.custom("Fredoka-Bold", size: 14))
                            .foregroundColor(gradeMovesTextColor)
                        Text(mentor.name)
                            .font(.custom("Fredoka-Bold", size: 25))
                            .foregroundColor(gradeMovesTextColor)
                    }
                    Spacer()
                }
                
                .padding(.horizontal, 15)
                .padding(.top, 16)

                Image(mentor.mentorImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 12) {
                    Text(mentor.role.uppercased())
                        .font(.custom("Fredoka-Bold", size: 12))
                        .kerning(1.5)
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#A7E2FF").opacity(0.5)))
                        .padding(.bottom, 4)
                    
                    // Gunakan 'text:' untuk string tunggal
                    InfoRow(label: "Career", text: mentor.career, icon: "briefcase.fill", color: gradeMovesTextColor)
                    // Gunakan 'texts:' untuk array
                    InfoRow(label: "Education", texts: mentor.education, icon: "graduationcap.fill", color: gradeMovesTextColor)
                    
                    if grade == .common {
                        LockedInfoRow(label: "Hobby", texts: mentor.hobby, icon: "heart.fill", color: Color(hex: "#FFB800"))
                        LockedInfoRow(label: "Fun Fact", texts: mentor.funFact, icon: "sparkles", color: Color(hex: "#9C27B0"))
                    } else {
                        InfoRow(label: "Hobby", texts: mentor.hobby, icon: "heart.fill", color: Color(hex: "#FFB800"))
                        InfoRow(label: "Fun Fact", texts: mentor.funFact, icon: "sparkles", color: Color(hex: "#9C27B0"))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                Spacer()

                HStack {
                    Spacer()
                    Text("Apple Developer Academy @ 2026")
                        .font(.custom("Fredoka-Regular", size: 12))
                        .foregroundColor(gradeMovesTextColor.opacity(0.6))
                        .padding(.trailing, 12)
                    Spacer()
                }
                .frame(height: 24)
                .background(gradeMovesTextColor.opacity(0.05))
                .padding(.bottom, 8)
            }
        }
        
        .frame(width: 400, height: 650)
        .rotation3DEffect(
            isRare ? .degrees(motionManager.tiltX * (isLegendary ? 15 : 10)) : .zero,
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.55
        )
        .shadow(
            color: isLegendary ? Color(hex: "#FFD700").opacity(0.6) : (isEpic ? Color.epiccard.opacity(0.4) : Color.black.opacity(0.1)),
            radius: isLegendary ? 30 : (isEpic ? 24 : 10),
            y: 6
        )
        .onAppear {
            if isRare { motionManager.start() }
        }
        .onDisappear {
            motionManager.stop()
        }
    }

    // Latar belakang kartu berdasarkan grade
    private var cardBgPlate: LinearGradient {
        if isLegendary {
            return LinearGradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFF1B8")], startPoint: .top, endPoint: .bottom)
        } else if isEpic {
            return LinearGradient(colors: [Color(hex: "#FDF4FF"), Color(hex: "#FCF0FF")], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color.white, Color(hex: "#F8FAFF")], startPoint: .top, endPoint: .bottom)
        }
    }

    // Gradien cat air untuk bingkai foto berdasarkan grade
    private var gradeWaterfallGradient: LinearGradient {
        if isLegendary {
            return LinearGradient(colors: [Color(hex: "#FFF9D2"), Color(hex: "#FFD700")], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isEpic {
            return LinearGradient(colors: [Color(hex: "#F3E5F5"), Color(hex: "#CE93D8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color(hex: "#D6F0FF"), Color(hex: "#82BBDD")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var borderGradient: LinearGradient {
        if isLegendary {
            return LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#FCA048"), Color(hex: "#FFD700")], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isEpic {
            return LinearGradient(colors: [Color(hex: "#FDF4FF"), Color(hex: "#FCF0FF"), Color(hex: "F3E5F5")], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color(hex: "#A7E2FF"), Color(hex: "#7CCFFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Reusable Info Row
struct InfoRow: View {
    let label: String
    let texts: [String] // Data utama disimpan dalam bentuk array
    let icon: String
    var color: Color

    // Opsi 1: Jika yang dimasukkan adalah String tunggal (Career, Hobby, Fun Fact)
    init(label: String, text: String, icon: String, color: Color = Color(hex: "#888888")) {
        self.label = label
        self.texts = [text] // Ubah otomatis jadi array berisi 1
        self.icon = icon
        self.color = color
    }

    // Opsi 2: Jika yang dimasukkan adalah Array (Education)
    init(label: String, texts: [String], icon: String, color: Color = Color(hex: "#888888")) {
        self.label = label
        self.texts = texts
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Fredoka-Bold", size: 12))
                    .foregroundColor(Color(hex: "#888888"))
                
                // Looping data dengan benar
                ForEach(texts, id: \.self) { item in
                    Text(texts.count > 1 ? "• \(item)" : item)
                        .font(.custom("Fredoka-SemiBold", size: 14))
                        .foregroundColor(Color(hex: "#555555"))
                        .fixedSize(horizontal: false, vertical: true) // Mencegah teks terpotong (...)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Locked Info Row (Untuk Hobby/FunFact di kartu Common)

struct LockedInfoRow: View {
    let label: String
    let texts: [String]
    let icon: String
    var color: Color

    // Opsi 1: Single String
    init(label: String, text: String, icon: String, color: Color = Color(hex: "#888888")) {
        self.label = label
        self.texts = [text]
        self.icon = icon
        self.color = color
    }

    // Opsi 2: Array String
    init(label: String, texts: [String], icon: String, color: Color = Color(hex: "#888888")) {
        self.label = label
        self.texts = texts
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Fredoka-Bold", size: 12))
                    .foregroundColor(Color(hex: "#888888"))
                
                ForEach(texts, id: \.self) { item in
                    Text(texts.count > 1 ? "• \(item)" : item)
                        .font(.custom("Fredoka-SemiBold", size: 14))
                        .foregroundColor(Color(hex: "#555555"))
                        .fixedSize(horizontal: false, vertical: true)
                        .blur(radius: 5)
                }
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(color)
        }
        .opacity(0.4)
    }
}

// MARK: - Motion Manager

@MainActor
class CardMotionManager: ObservableObject {
    @Published var tiltX: Double = 0
    @Published var tiltY: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion, let self = self else { return }
            Task { @MainActor in
                self.tiltX = max(-1, min(1, motion.gravity.x * 2.5))
                self.tiltY = max(-1, min(1, motion.gravity.y * 2.5))
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
