//
//  GalleryView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI

// MARK: - Gallery View

struct GalleryView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedEntry: GalleryEntry? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Premium Sky Background (Consistent with Dashboard)
                LinearGradient(
                    colors: [Color(hex: "#F2FAFF"), Color(hex: "#D6F0FF")],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        galleryHeader
                        
                        // Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(gameState.gallery) { entry in
                                GalleryThumbnail(entry: entry)
                                    .onTapGesture {
                                        playSound("click")
                                        if entry.isUnlocked {
                                            selectedEntry = entry
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedEntry) { entry in
                ZStack {
                    // 1. Latar Belakang Premium Base
                    Color(hex: "#F2FAFF").ignoresSafeArea()
                    
                    // 2. Dynamic Glowing Aura (Aura cahaya di belakang kartu sesuai Grade)
                    Circle()
                        .fill(
                            entry.grade == .legendary ? Color(hex: "#FFD700").opacity(0.4) :
                                (entry.grade == .epic ? Color(hex: "#D4B8FF").opacity(0.4) : Color(hex: "#82BBDD").opacity(0.3))
                        )
                        .blur(radius: 80)
                        .frame(width: 300, height: 300)
                        .offset(y: -30)
                    
                    VStack(spacing: 0) {
                        // 3. Custom Header (Drag Handle + Close Button)
                        ZStack {
                            Capsule()
                                .fill(Color(hex: "#82BBDD").opacity(0.4))
                                .frame(width: 48, height: 5)
                            
                            HStack {
                                Spacer()
                                Button(action: { selectedEntry = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "#82BBDD"))
                                        .background(Circle().fill(Color.white).frame(width: 24, height: 24))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 50)
                        
                        // 4. Kartu Mentor Pokemon Raksasa
                        MentorCardFront(mentor: entry.mentor, grade: entry.grade)
                            .scaleEffect(0.9)
                            .frame(width: 400 * 0.9, height: 650  * 0.9)
                        
                        Spacer()
                    }
                }
                // Atur detent ke 85% layar agar terlihat elegan dan proporsional
                .presentationDetents([.fraction(0.9)])
                .presentationCornerRadius(40)
                .presentationDragIndicator(.hidden)
            }
        }
    }
    
    // MARK: — Header
    
    private var galleryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Collection")
                    .font(.custom("Fredoka-Bold", size: 32))
                    .foregroundColor(Color.textPrimary)
                
                Text("\(gameState.unlockedCount) of 19 cards collected")
                    .font(.custom("Fredoka-Regular", size: 16))
                    .foregroundColor(Color.textSecondary)
            }
            
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color(hex: "#90C2E7").opacity(0.5), radius: 12, y: 6)
                
                Circle()
                    .stroke(Color(hex: "#E8F4FA"), lineWidth: 5)
                
                Circle()
                    .trim(from: 0, to: CGFloat(gameState.unlockedCount) / CGFloat(18.0))
                    .stroke(
                        LinearGradient(colors: [Color.textPrimary, Color.textPrimary], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: gameState.unlockedCount)
                
                Text("\(Int(Double(gameState.unlockedCount) / Double(19.0) * 100))%")
                    .font(.custom("Fredoka-Bold", size: 15))
                    .foregroundColor(Color.textPrimary)
            }
            .frame(width: 64, height: 64)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Gallery Thumbnail
    
    struct GalleryThumbnail: View {
        let entry: GalleryEntry
        @State private var glowPulse: Bool = false
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: (entry.grade == .epic || entry.grade == .legendary) ? 2 : 1)
                    )
                    .shadow(color: shadowColor, radius: glowPulse ? 15 : 8, y: 4)
                
                if !entry.isUnlocked {
                    lockedContent
                } else {
                    unlockedContent
                }
            }
            .aspectRatio(0.75, contentMode: .fit)
            .onAppear {
                if (entry.grade == .epic || entry.grade == .legendary) && entry.isUnlocked {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }
            }
        }
        
        // MARK: — Colors
        private var cardBg: Color {
            if !entry.isUnlocked { return Color.white.opacity(0.5) }
            if entry.grade == .legendary { return Color(hex: "#FFF8E1") }
            return entry.grade == .epic ? Color(hex: "#FDF4FF") : Color.white
        }
        
        private var borderColor: Color {
            if !entry.isUnlocked { return Color(hex: "#82BBDD").opacity(0.3) }
            if entry.grade == .legendary { return Color(hex: "#FCA048") }
            return entry.grade == .epic ? Color.epiccard : Color(hex: "#A7E2FF")
        }
        
        private var shadowColor: Color {
            if !entry.isUnlocked { return Color(hex: "#82BBDD").opacity(0.1) }
            if entry.grade == .legendary { return Color(hex: "#FFD700").opacity(0.5) }
            return entry.grade == .epic
            ? Color(hex: "#FDF4FF").opacity(0.3)
            : Color(hex: "#82BBDD").opacity(0.2)
        }
        
        // MARK: — Locked State
        private var lockedContent: some View {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.textSecondary)
                Text(entry.mentor.nickname)
                    .font(.custom("Fredoka-Bold", size: 14))
                    .foregroundColor(Color(hex: "#82BBDD"))
                    .multilineTextAlignment(.center)
            }
        }
        
        // MARK: — Unlocked State
        private var unlockedContent: some View {
            VStack(spacing: 6) {
                if entry.grade == .legendary {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(entry.grade == .legendary ? Color(hex: "#FCA048") : Color(hex: "#FFB800"))
                            .padding([.top, .trailing], 8)
                    }
                } else {
                    Spacer().frame(height: 14)
                }
                
                // Slightly larger avatar in the grid
                ZStack {
                    Circle()
                        .fill(Color(hex: entry.mentor.accentColor).opacity(0.2))
                        .frame(width: 58, height: 58)
                    Image(entry.mentor.mentorImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color(hex: entry.mentor.accentColor))
                        .clipShape(Circle())
                }.padding(.bottom, 3)
                
                VStack(spacing: 2) {
                    Text(entry.mentor.nickname)
                        .font(.custom("Fredoka-Bold", size: 16))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)
        
                    Text(entry.mentor.role.contains("Product") ? "Product & Growth \n Mentor" : entry.mentor.role)
                        .font(.custom("Fredoka-Regular", size: 11))
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 6)
                
                Spacer()
            }
        }
    }
}


// MARK: - Restyled Info Row for White Background

struct InsideInfoRow: View {
    let label: String
    let value: String
    let icon: String
    var highlightColor: Color = Color(hex: "#42A5F5") // Default Blue
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(highlightColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(highlightColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Fredoka-Bold", size: 14))
                    .foregroundColor(Color(hex: "#82BBDD"))
                Text(value)
                    .font(.custom("Fredoka-Regular", size: 17))
                    .foregroundColor(Color.textPrimary) // Deep Navy
                    .fixedSize(horizontal: false, vertical: true) // Prevents text truncation
            }
            Spacer()
        }
    }
}
