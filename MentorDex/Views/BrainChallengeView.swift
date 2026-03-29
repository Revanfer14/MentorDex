//
//  BrainChallengeView.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI
import FoundationModels
import Combine

// MARK: - 1. UI Question Model
struct GeneratedQuestion {
    var question: String
    var options: [String]
    var category: String
    var correctAnswerIndex: Int
}

// MARK: - 2. AI Payload Schema
@available(iOS 26.0, *)
@Generable
struct AIPayload {
    @Guide(description: "A clear, concise general knowledge question.")
    var question: String
    
    @Guide(description: "The exact, correct answer to the question.")
    var correctAnswer: String
    
    @Guide(description: "Exactly 3 plausible but incorrect answers.")
    @Guide(.count(3))
    var wrongAnswers: [String]
}

// MARK: - Quiz Service

@available(iOS 26.0, *)
@MainActor
class QuizService: ObservableObject {
    
    @Published var question: GeneratedQuestion? = nil
    @Published var isLoading: Bool = false
    
    private var session: LanguageModelSession?
    
    func generateQuestion(tier: ChallengeTier) async {
        // Dummy data for Canvas Previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.question = GeneratedQuestion(
                question: "What is the largest ocean on Earth?",
                options: ["Atlantic", "Indian", "Arctic", "Pacific"],
                category: "general",
                correctAnswerIndex: 3
            )
            self.isLoading = false
            return
        }
        
        isLoading = true
        question = nil
        
        let category = ["math", "general"].randomElement()!
        
        if category == "math" {
            self.question = generateNativeMath(tier: tier)
            isLoading = false
            return
        }
        
        let instructions = systemInstructions(tier: tier)
        let topicSeed = [
            "Science", "Space", "Animals", "Computer Science History", "Apple Innovations", "Video Games",
            "Movies", "Korean Dramas", "Music", "World Landmarks", "Anime", "Music Artist", "Celebrities"
        ].randomElement()!
        
        // Membatasi keliaran AI
        let userPrompt = """
        Generate a fun Tier \(tier.rawValue) trivia question about \(topicSeed). 
        Make it exciting! Avoid boring history dates question.
        Ensure ALL 4 answer choices (1 correct + 3 wrong) are 100% DIFFERENT from one another.
        """
        
        session = LanguageModelSession(instructions: instructions)
        
        do {
            let response = try await session!.respond(
                to: userPrompt,
                generating: AIPayload.self
            )
            
            let payload = response.content
            
            var allOptions = payload.wrongAnswers
            allOptions.append(payload.correctAnswer)
            allOptions.shuffle()
            
            let correctIndex = allOptions.firstIndex(of: payload.correctAnswer) ?? 0
            
            self.question = GeneratedQuestion(
                question: payload.question,
                options: allOptions,
                category: "general",
                correctAnswerIndex: correctIndex
            )
            
        } catch {
            self.question = fallbackQuestion(tier: tier)
        }
        
        isLoading = false
    }
    
    private func systemInstructions(tier: ChallengeTier) -> String {
        """
        You are a highly balanced trivia game engine for MentorDex. Generate EXACTLY ONE multiple-choice question based on the requested topic and tier.
        
        CRITICAL RULES FOR OPTIONS (ANTI-DUPLICATE):
            1. You MUST provide exactly 3 `wrongAnswers`.
            2. EVERY single option in `wrongAnswers` MUST BE COMPLETELY UNIQUE AND DIFFERENT from each other.
            3. The `wrongAnswers` MUST NOT contain the `correctAnswer`.
        
        DIFFICULTY & TONE:
        • Tier 1 (Easy): Must be answerable by an average 12-year-old. Extremely common knowledge.
          Good Example: "Which planet is known as the Red Planet?"
          Bad Example: "What is the exact chemical composition of Mars?"
          
        • Tier 2 (Medium): Standard pub trivia. Requires some thought but widely known.
          Good Example: "Who directed the movie 'Jurassic Park'?"
          Bad Example: "Who was the 3rd assistant director of 'Jurassic Park'?"
          
        • Tier 3 (Hard): Challenging, but MUST BE DEDUCIBLE. DO NOT ask for exact dates or random population numbers. Focus on fascinating "Aha!" moments.
          Good Example: "Which animal has fingerprints so indistinguishable from humans that they have confused crime scenes?" (Answer: Koala)
          Bad Example: "In what year did scientists discover Koala fingerprints?"
        
        STRICT FORMATTING:
        1. Question Length: Under 15 words. Fast to read.
        2. Factual Accuracy: The `correctAnswer` MUST be 100% accurate.
        3. Quality Distractors: Provide exactly 3 `wrongAnswers`. Make them tricky but plausible. DO NOT use joke answers.
        4. Make sure there is NO SAME choice of answers.
        5. Output ONLY the valid JSON payload.
        """
    }
    
    private func generateNativeMath(tier: ChallengeTier) -> GeneratedQuestion {
        let qText: String
        let answer: Int
        
        switch tier {
        case .tier1:
            let a = Int.random(in: 1...20)
            let b = Int.random(in: 1...20)
            qText = "What is \(a) * \(b)?"
            answer = a * b
        case .tier2:
            let a = Int.random(in: 100...999)
            let b = Int.random(in: 50...999)
            let c = Int.random(in: 9...99)
            qText = "What is \(a) + \(b) − \(c)?"
            answer = a + b - c
        case .tier3:
            let a = Int.random(in: 101...999)
            let b = Int.random(in: 10...55)
            let c = Int.random(in: 10...55)
            let d = Int.random(in: 100...999)
            qText = "What is (\(a) - \(b)) + \(c) - \(d)?"
            answer = (a - b) + c - d
        }
        
        let wrong1 = answer + Int.random(in: 1...9)
        let wrong2 = answer - Int.random(in: 1...9)
        let wrong3 = answer + 10
        
        var options = [String(wrong1), String(wrong2), String(wrong3), String(answer)]
        options.shuffle()
        let correctIdx = options.firstIndex(of: String(answer)) ?? 0
        
        return GeneratedQuestion(
            question: qText,
            options: options,
            category: "math",
            correctAnswerIndex: correctIdx
        )
    }
    
    private func fallbackQuestion(tier: ChallengeTier) -> GeneratedQuestion {
        return GeneratedQuestion(
            question: "What is 34 + 81?",
            options: ["111", "115", "117", "120"],
            category: "math",
            correctAnswerIndex: 1
        )
    }
}

// MARK: - Brain Challenge View (Main UI)

@available(iOS 26.0, *)
struct BrainChallengeView: View {
    let tier: ChallengeTier
    var dismissAll: (() -> Void)? = nil
    
    @EnvironmentObject var gameState: GameState
    @StateObject private var quizService = QuizService()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedAnswer: Int? = nil
    @State private var isAnswerRevealed = false
    @State private var timeRemaining: Double = 10
    @State private var timerActive = false
    @State private var navigateToReward = false
    @State private var earnedCards: [GameState.RewardCard] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var showResult = false
    @State private var showFailBanner = false
    @State private var isAnimatingBolts = false
    @State private var showPackChoice = false
    
    // MARK: - Multi-Round State
    @State private var currentRound = 1
    @State private var correctAnswers = 0
    @State private var wrongAns = 0
    private var totalTime: Double = 10.0
    
    private var totalRounds: Int {
        switch tier {
        case .tier1: return 1
        case .tier2, .tier3: return 3
        }
    }
    
    init(tier: ChallengeTier, dismissAll: (() -> Void)? = nil) {
        self.tier = tier
        self.dismissAll = dismissAll
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                Group {
                    if quizService.isLoading {
                        loadingView
                    } else if let q = quizService.question {
                        questionView(q)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                    }
                }
                
                resultOverlay
                if showFailBanner { failBanner }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $navigateToReward) {
                PackOpeningView(tier: tier, rewardCards: earnedCards, dismissAll: dismissAll)
                    .environmentObject(gameState)
            }
            .onAppear {
                playMusic("quizmusic", true)
            }
            .onDisappear {
                playMusic("main-bgm", true)
            }
            .task {
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
                await quizService.generateQuestion(tier: tier)
                startTimer()
            }
        }
    }
    
    // MARK: — Premium Background
    
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F2FAFF"), Color(hex: "#D6F0FF")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "#D4B8FF").opacity(0.4))
                .blur(radius: 60)
                .frame(width: 250)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color(hex: "#A7E2FF").opacity(0.6))
                .blur(radius: 80)
                .frame(width: 300)
                .offset(x: 150, y: 300)
        }
    }
    
    // MARK: — Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#FFD700"))
                        .shadow(color: Color(hex: "#FFB800").opacity(isAnimatingBolts ? 0.8 : 0), radius: 8, y: 0)
                        .scaleEffect(isAnimatingBolts ? 1.3 : 0.7)
                        .opacity(isAnimatingBolts ? 1.0 : 0.3)
                        .offset(y: isAnimatingBolts ? -10 : 0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: isAnimatingBolts
                        )
                }
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 6) {
                Text("Pikachu is generating...")
                    .font(.custom("Fredoka-Bold", size: 24))
                    .foregroundColor(Color.textPrimary)
                
                Text(currentRound > 1 ? "Preparing Round \(currentRound) ⚡️" : "Preparing your challenge ⚡️")
                    .font(.custom("Fredoka-Regular", size: 16))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .onAppear {
            isAnimatingBolts = true
        }
    }
    
    // MARK: — Question View
    
    private func questionView(_ q: GeneratedQuestion) -> some View {
        VStack(spacing: 0) {
            questionHeader(q)
            
            VStack(spacing: 25) {
                Text(q.question)
                    .font(.custom("Fredoka-Bold", size: 20))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.5)
                    .offset(x: shakeOffset)
                    .shadow(color: Color.textPrimary.opacity(0.1), radius: 10, y: 4)
                    .padding(.top, 35)
                    .padding(.bottom, 20)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<q.options.count, id: \.self) { idx in
                        AnswerButton(
                            text: q.options[idx],
                            state: answerState(for: idx, correct: q.correctAnswerIndex),
                            onTap: { submitAnswer(idx, correct: q.correctAnswerIndex) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .disabled(isAnswerRevealed)
                
                Spacer()
            }
        }
    }
    
    // MARK: — Header
    
    private func questionHeader(_ q: GeneratedQuestion) -> some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.6)))
                }
                
                Spacer()
                
                // Round Indicator (If applicable)
                if totalRounds > 1 {
                    Text("Round \(currentRound)/\(totalRounds)")
                        .font(.custom("Fredoka-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                }
                
                Text("Tier \(tier.rawValue)")
                    .font(.custom("Fredoka-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(tier.packColor))
                    .shadow(color: tier.packColor.opacity(0.4), radius: 4, y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            
            timerView
            
            HStack(spacing: 6) {
                Text(categoryEmoji(q.category))
                Text(q.category.capitalized)
                    .font(.custom("Fredoka-Bold", size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.8)))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
    }
    
    // MARK: — Sleek Timer Bar
    
    private var timerView: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.5))
                    Capsule()
                        .fill(timerColor)
                        .frame(width: geo.size.width * CGFloat(max(0, timeRemaining) / totalTime))
                        .animation(.linear(duration: 0.1), value: timeRemaining)
                        .shadow(color: timerColor.opacity(0.6), radius: 4, y: 0)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 24)
            
            Text(String(format: "%.1fs", max(timeRemaining, 0)))
                .font(.custom("Fredoka-Bold", size: 36))
                .foregroundColor(timerColor)
                .contentTransition(.numericText())
                .scaleEffect(timeRemaining < 3.0 && Int(timeRemaining * 10) % 5 == 0 ? 1.1 : 1.0)
                .animation(.spring(), value: timeRemaining)
        }
    }
    
    private var timerColor: Color {
        let frac = timeRemaining / totalTime
        if frac > 0.4 { return Color(hex: "#42A5F5") } // Blue
        if frac > 0.2 { return Color(hex: "#F59E0B") } // Orange
        return Color(hex: "#EF4444") // Red
    }
    
    private func categoryEmoji(_ cat: String) -> String {
        switch cat {
        case "math":    return "➕"
        case "general": return "🌍"
        default:        return "❓"
        }
    }
    
    // MARK: — Game Logic
    
    private func answerState(for idx: Int, correct: Int) -> AnswerButtonState {
        guard isAnswerRevealed else { return .normal }
        if idx == correct { return .correct }
        if idx == selectedAnswer { return .wrong }
        return .neutral
    }
    
    private func startTimer() {
        guard quizService.question != nil else { return }
        timeRemaining = totalTime
        timerActive = true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            Task { @MainActor in
                guard self.timerActive else { timer.invalidate(); return }
                self.timeRemaining -= 0.1
                if self.timeRemaining <= 0 {
                    timer.invalidate()
                    self.timerActive = false
                    self.handleTimeout()
                }
            }
        }
    }
    
    private func handleTimeout() {
        guard !isAnswerRevealed else { return }
        isAnswerRevealed = true
        
        wrongAns += 1
        
        shake()
        scheduleFinish()
    }
    
    private func submitAnswer(_ idx: Int, correct: Int) {
        guard !isAnswerRevealed else { return }
        timerActive = false
        selectedAnswer = idx
        isAnswerRevealed = true
        
        if idx == correct {
            playSound("correctanswer")
            correctAnswers += 1
        } else {
            playSound("wronganswer")
            wrongAns += 1
            shake()
        }
        
        scheduleFinish()
    }
    
    private func shake() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { shakeOffset = 14 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring()) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring()) { shakeOffset = 0 }
        }
    }
    
    private func scheduleFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            
            var forceStop = false
            
            if self.tier == .tier3 && self.wrongAns > 0 {
                forceStop = true
            } else if self.tier == .tier2 {
                if self.wrongAns >= 2 {
                    forceStop = true
                } else if self.correctAnswers >= 2 {
                    forceStop = true
                }
            }
            
            if self.currentRound < self.totalRounds && !forceStop {
                // Lanjut next round
                withAnimation(.spring()) {
                    self.currentRound += 1
                    self.selectedAnswer = nil
                    self.isAnswerRevealed = false
                    self.timeRemaining = self.totalTime
                }
                
                Task {
                    await quizService.generateQuestion(tier: self.tier)
                    startTimer()
                }
            } else {
                self.handleFinalResults()
            }
        }
    }
    
    private func handleFinalResults() {
        AudioManager.shared.stopBGM()
        
        var didWin = false
        
        switch tier {
        case .tier1:
            didWin = correctAnswers >= 1
        case .tier2:
            didWin = correctAnswers >= 2
        case .tier3:
            didWin = correctAnswers == 3
        }
        
        if didWin {
            playSound("victory")
            playHaptic(style: .heavy, intensity: 1.0)
            withAnimation(.spring()) { showPackChoice = true }
        } else {
            playSound("fail")
            playHaptic(style: .heavy, intensity: 1.0)
            
            if tier == .tier3 && currentRound < totalRounds {
                playHaptic(style: .heavy, intensity: 1.0)
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showFailBanner = true
            }
        }
    }
    
    // MARK: — Result Overlay (correct)
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Ikon Pack Terbang
                Image(tier.packImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 100)
                
                VStack(spacing: 8) {
                    Text("Challenge Passed!")
                        .font(.custom("Fredoka-Bold", size: 24))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("You earned a \(tier.packLabel).")
                        .font(.custom("Fredoka-Regular", size: 18))
                        .foregroundColor(Color.textSecondary)
                }
                
                VStack(spacing: 16) {
                    // Tombol Buka Langsung
                    Button(action: {
                        earnedCards = gameState.distributeRewards(tier: tier)
                        navigateToReward = true
                    }) {
                        Text("Open Now")
                            .font(.custom("Fredoka-Bold", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Capsule().fill(tier.packColor).shadow(color: tier.packColor.opacity(0.4), radius: 10, y: 5))
                    }
                    
                    // Tombol Simpan ke Dashboard
                    Button(action: {
                        gameState.savePackToInventory(tier: tier)
                        if let dismissAll = dismissAll { dismissAll() } else { dismiss() }
                    }) {
                        Text("Save to Inventory")
                            .font(.custom("Fredoka-Bold", size: 18))
                            .foregroundColor(tier.packColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Capsule().fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 10, y: 5))
                            .overlay(Capsule().stroke(tier.packColor.opacity(0.3), lineWidth: 2))
                    }
                }
                .padding(.top, 16)
            }
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 40).fill(Color.white))
            .shadow(color: Color.black.opacity(0.15), radius: 30, y: 15)
            .padding(.horizontal, 24)
        }
        .opacity(showPackChoice ? 1 : 0) // Gunakan logic opacity agar bisa transisi mulus
    }
    
    // MARK: — Fail Banner (wrong / timeout)
    
    private var failBanner: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("😤")
                    .font(.system(size: 80))
                    .scaleEffect(showFailBanner ? 1.0 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showFailBanner)
                
                Text("You Failed!")
                    .font(.custom("Fredoka-Bold", size: 38))
                    .foregroundColor(.white)
                
                Text(tier == .tier1 ? "Answer the question correctly\nto earn a pack." : "You need more correct answers\nto earn this pack.")
                    .font(.custom("Fredoka-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: { dismiss() }) {
                    Text("Try Again")
                        .font(.custom("Fredoka-Bold", size: 22))
                        .foregroundColor(Color(hex: "#7F1D1D"))
                        .padding(.horizontal, 48)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                        )
                }
                .padding(.top, 8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(LinearGradient(colors: [Color(hex: "#B91C1C"), Color(hex: "#991B1B")], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Color(hex: "#991B1B").opacity(0.5), radius: 30, y: 15)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Answer Button State

enum AnswerButtonState { case normal, correct, wrong, neutral }

// MARK: - Premium Answer Button

struct AnswerButton: View {
    let text: String
    let state: AnswerButtonState
    let onTap: () -> Void
    
    @State private var pressed = false
    
    private var bgColor: LinearGradient {
        switch state {
        case .normal:  return LinearGradient(colors: [.white, Color(hex: "#F9FAFB")], startPoint: .top, endPoint: .bottom)
        case .correct: return LinearGradient(colors: [Color(hex: "#34D399"), Color(hex: "#10B981")], startPoint: .top, endPoint: .bottom) // Vibrant Green
        case .wrong:   return LinearGradient(colors: [Color(hex: "#F87171"), Color(hex: "#EF4444")], startPoint: .top, endPoint: .bottom) // Vibrant Red
        case .neutral: return LinearGradient(colors: [Color(hex: "#E5E7EB"), Color(hex: "#D1D5DB")], startPoint: .top, endPoint: .bottom) // Gray
        }
    }
    
    private var textColor: Color {
        switch state {
        case .normal: return Color.textPrimary
        case .correct, .wrong: return .white
        case .neutral: return Color(hex: "#6B7280")
        }
    }
    
    private var shadowColor: Color {
        switch state {
        case .normal: return Color(hex: "#82BBDD").opacity(0.2)
        case .correct: return Color(hex: "#10B981").opacity(0.4)
        case .wrong: return Color(hex: "#EF4444").opacity(0.4)
        case .neutral: return .clear
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { pressed = false }
            onTap()
        }) {
            Text(text)
                .font(.custom("Fredoka-Bold", size: 18))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity, minHeight: 90)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(bgColor)
                        .shadow(color: shadowColor, radius: 10, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(state == .normal ? 1.0 : 0.3), lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.92 : 1.0)
        .animation(.spring(), value: state)
    }
}
