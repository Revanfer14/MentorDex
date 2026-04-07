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
    
    func generateQuestion() async {
        isLoading = true
        question = nil
        
        // Efek loading UI
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let category = pickCategory()
        
        if category == "math" {
            self.question = generateNativeMath()
        } else if category == "academy" {
            self.question = generateLocalAcademyQuestion()
        } else {
            await generateAIGeneralQuestion()
        }
        
        isLoading = false
    }
    
    private func pickCategory() -> String {
        let roll = Int.random(in: 1...100)
        
        switch roll {
        case 1...80:
            return "academy"
        case 81...90:
            return "general"
        default:
            return "math"
        }
    }
    
    // Academy Questions
    private func generateLocalAcademyQuestion() -> GeneratedQuestion {
        let selected = QuestionBank.all.randomElement()!
        
        var options = selected.wrongs
        options.append(selected.correct)
        options.shuffle()
        
        let correctIdx = options.firstIndex(of: selected.correct) ?? 0
        return GeneratedQuestion(question: selected.question, options: options, category: "Academy", correctAnswerIndex: correctIdx)
    }
    
    // --- NATIVE MATH ---
    private func generateNativeMath() -> GeneratedQuestion {
        let a = Int.random(in: 10...99)
        let b = Int.random(in: 10...99)
        let c = Int.random(in: 10...99)
        
        // Acak operator: Tambah atau Kurang
        let isPlus = Bool.random()
        let qText = isPlus ? "What is \(a) + \(b) - \(c)?" : "What is \(a) * 2 + \(b)?"
        let answer = isPlus ? (a + b - c) : (a * 2 + b)
        
        let wrong1 = answer + Int.random(in: 1...10)
        let wrong2 = answer - Int.random(in: 1...10)
        let wrong3 = answer + 10
        
        var options = [String(wrong1), String(wrong2), String(wrong3), String(answer)]
        options.shuffle()
        let correctIdx = options.firstIndex(of: String(answer)) ?? 0
        
        return GeneratedQuestion(question: qText, options: options, category: "Math", correctAnswerIndex: correctIdx)
    }
    
    // --- AI FOUNDATION MODELS ---
    private func generateAIGeneralQuestion() async {
        // 1. Variasi Topik: Tambahkan sebanyak mungkin kategori dasar yang menyenangkan
        let categories = [
            "Animals", "Pop Culture", "Music", "Movies", "Sports",
            "Technology", "Famous Landmarks", "Country",
            "Video Games","Computer Science", "Technology"
        ]
        let selectedCategory = categories.randomElement()!
        
        // 2. Instruksi yang lebih terarah dan spesifik untuk On-Device AI
        let instructions = """
            You are a fun and engaging trivia game engine.
            Generate ONE multiple-choice question based on the category: \(selectedCategory).
            
            Rules:
            1. Difficulty: EASY (Basic general knowledge, commonly known facts).
            2. Keep the question short, direct, and strictly under 15 words.
            3. Provide exactly 1 `correctAnswer`.
            4. Provide exactly 3 `wrongAnswers` that are plausible but completely incorrect.
            5. Make sure there are NO SAME choice of answers.
            6. Ensure the correct answer is an absolute fact.
            7. Do NOT use negative framing like "Which of these is NOT...".
            """
        
        // 3. Trigger prompt yang spesifik pada kategori yang terpilih
        let userPrompt = "Generate a fun, easy trivia question about \(selectedCategory) right now."
        
        session = LanguageModelSession(instructions: instructions)
        
        do {
            let response = try await session!.respond(to: userPrompt, generating: AIPayload.self)
            let payload = response.content
            
            var allOptions = payload.wrongAnswers
            allOptions.append(payload.correctAnswer)
            allOptions.shuffle()
            let correctIndex = allOptions.firstIndex(of: payload.correctAnswer) ?? 0
            
            self.question = GeneratedQuestion(
                question: payload.question,
                options: allOptions,
                category: selectedCategory, // UI akan menampilkan "Movies", "Animals", dll bukan cuma "General"
                correctAnswerIndex: correctIndex
            )
        } catch {
            // Jika AI gagal/offline, fallback ke pertanyaan Academy lokal
            self.question = generateLocalAcademyQuestion()
        }
    }
}

// MARK: - Struct Active Pack
struct ActivePackOpening: Identifiable {
    let id = UUID()
    let tier: ChallengeTier
    let cards: [GameState.RewardCard]
}

// MARK: - Brain Challenge View (Main UI)

@available(iOS 26.0, *)
struct BrainChallengeView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var quizService = QuizService()
    
    @State private var selectedAnswer: Int? = nil
    @State private var isAnswerRevealed = false
    @State private var timeRemaining: Double = 15
    @State private var timerActive = false
    
    @State private var shakeOffset: CGFloat = 0
    @State private var showResult = false
    @State private var isAnimatingBolts = false
    
    // MARK: - Multi-Round State (Fix 5 Rounds)
    @State private var currentRound = 1
    @State private var correctAnswers = 0
    private let totalRounds = 5
    private let totalTime: Double = 15.0
    
    @State private var coinsEarned = 0
    
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
                
                if showResult {
                    resultOverlay
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                playMusic("quizmusic", true)
            }
            .onDisappear {
                playMusic("main-bgm", true)
            }
            .task {
                await quizService.generateQuestion()
                startTimer()
            }
        }
    }
    
    // MARK: — UI Components
    
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F2FAFF"), Color(hex: "#D6F0FF")], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            Circle().fill(Color(hex: "#D4B8FF").opacity(0.4)).blur(radius: 60).frame(width: 250).offset(x: -100, y: -200)
            Circle().fill(Color(hex: "#A7E2FF").opacity(0.6)).blur(radius: 80).frame(width: 300).offset(x: 150, y: 300)
        }
    }
    
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
            isAnimatingBolts = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isAnimatingBolts = true
            }
        }
        .onDisappear {
            isAnimatingBolts = false
        }
    }
    
    private func questionView(_ q: GeneratedQuestion) -> some View {
        VStack(spacing: 0) {
            questionHeader(q)
            
            VStack(spacing: 25) {
                Text(q.question)
                    .font(.custom("Fredoka-Bold", size: 20))
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.5)
                    .offset(x: shakeOffset)
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
    
    private func questionHeader(_ q: GeneratedQuestion) -> some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(.gray).frame(width: 40, height: 40).background(Circle().fill(Color.white.opacity(0.6)))
                }
                Spacer()
                Text("Round \(currentRound)/\(totalRounds)")
                    .font(.custom("Fredoka-Bold", size: 14)).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(Color.black.opacity(0.25)))
            }
            .padding(.horizontal, 24).padding(.top, 60)
            
            timerView
            
            // 🌟 INDIKATOR KATEGORI SOAL (Menampilkan dari mana soal berasal)
            HStack(spacing: 6) {
                Text(categoryEmoji(q.category))
                Text(q.category)
                    .font(.custom("Fredoka-Bold", size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.8)))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.5))
                    Capsule().fill(timerColor).frame(width: geo.size.width * CGFloat(max(0, timeRemaining) / totalTime)).animation(.linear(duration: 0.1), value: timeRemaining)
                }
            }
            .frame(height: 12).padding(.horizontal, 24)
            
            Text(String(format: "%.1fs", max(timeRemaining, 0)))
                .font(.custom("Fredoka-Bold", size: 36)).foregroundColor(timerColor).contentTransition(.numericText())
        }
    }
    
    private var timerColor: Color {
        let frac = timeRemaining / totalTime
        if frac > 0.4 { return Color(hex: "#42A5F5") }
        if frac > 0.2 { return Color(hex: "#F59E0B") }
        return Color(hex: "#EF4444")
    }
    
    private func categoryEmoji(_ cat: String) -> String {
        switch cat {
        case "Math":    return "➕"
        case "General": return "🤖" // Ikon Robot AI
        case "Academy": return "🍏" // Ikon Apple Academy
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
            shake()
        }
        scheduleFinish()
    }
    
    private func shake() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { shakeOffset = 14 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { withAnimation(.spring()) { shakeOffset = -10 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { withAnimation(.spring()) { shakeOffset = 0 } }
    }
    
    private func scheduleFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.currentRound < self.totalRounds {
                withAnimation(.spring()) {
                    self.currentRound += 1
                    self.selectedAnswer = nil
                    self.isAnswerRevealed = false
                    self.timeRemaining = self.totalTime
                }
                Task {
                    await quizService.generateQuestion()
                    startTimer()
                }
            } else {
                self.calculateAndShowResults()
            }
        }
    }
    
    private func calculateAndShowResults() {
        AudioManager.shared.stopBGM()
        
        switch correctAnswers {
        case 0: coinsEarned = 0
        case 1: coinsEarned = 2
        case 2: coinsEarned = 4
        case 3: coinsEarned = 8
        case 4: coinsEarned = 10
        case 5: coinsEarned = 15
        default: coinsEarned = 0
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            playSound("victory")
            showResult = true
        }
    }
    
    // MARK: — Result Overlay (Coins Earned)
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).background(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Quiz Completed!")
                        .font(.custom("Fredoka-Bold", size: 28))
                        .foregroundColor(.black.opacity(0.9))
                    
                    Text("You answered \(correctAnswers) out of 5 correctly.")
                        .font(.custom("Fredoka-Regular", size: 18))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("Reward")
                        .font(.custom("Fredoka-Bold", size: 16))
                        .foregroundColor(.gray)
                    Text("+\(coinsEarned) Coins")
                        .font(.custom("Fredoka-Bold", size: 36))
                        .foregroundColor(Color(hex: "#F59E0B"))
                }
                .padding(.vertical, 16)
                
                Button(action: {
                    gameState.addCoins(coinsEarned)
                    playSound("click")
                    playHaptic(style: .medium)
                    dismiss()
                }) {
                    Text("Claim & Exit")
                        .font(.custom("Fredoka-Bold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Color.starterpack))
                }
            }
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 40).fill(Color.white))
            .shadow(color: Color.black.opacity(0.2), radius: 30, y: 15)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Answer Button

enum AnswerButtonState { case normal, correct, wrong, neutral }

struct AnswerButton: View {
    let text: String
    let state: AnswerButtonState
    let onTap: () -> Void
    @State private var pressed = false
    
    private var bgColor: LinearGradient {
        switch state {
        case .normal:  return LinearGradient(colors: [.white, Color(hex: "#F9FAFB")], startPoint: .top, endPoint: .bottom)
        case .correct: return LinearGradient(colors: [Color(hex: "#34D399"), Color(hex: "#10B981")], startPoint: .top, endPoint: .bottom)
        case .wrong:   return LinearGradient(colors: [Color(hex: "#F87171"), Color(hex: "#EF4444")], startPoint: .top, endPoint: .bottom)
        case .neutral: return LinearGradient(colors: [Color(hex: "#E5E7EB"), Color(hex: "#D1D5DB")], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var textColor: Color {
        switch state {
        case .normal: return .black.opacity(0.8)
        case .correct, .wrong: return .white
        case .neutral: return Color(hex: "#6B7280")
        }
    }
    
    var body: some View {
        Button(action: {
            playHaptic(style: .medium)
            withAnimation(.spring()) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { pressed = false }
            onTap()
        }) {
            Text(text)
                .font(.custom("Fredoka-Bold", size: 16))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 90)
                .background(RoundedRectangle(cornerRadius: 24).fill(bgColor).shadow(color: Color.black.opacity(0.05), radius: 5, y: 2))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(state == .normal ? 1.0 : 0.3), lineWidth: 2))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.92 : 1.0)
    }
}
