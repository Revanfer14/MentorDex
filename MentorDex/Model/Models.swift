// Models.swift
// MentorDex — Core Data Models

import Foundation
import SwiftUI

// MARK: - Mentor Model

struct Mentor: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let role: String
    let career: String
    let education: String
    let hobby: String
    let funFact: String
    let photoSystemName: String 
    let accentColor: String
}

// MARK: - Card Grade

enum CardGrade: String, Codable, CaseIterable {
    case common = "Common"
    case epic = "Epic"
    case legendary = "Legendary"
}

// MARK: - Gallery Entry (what the user owns)

struct GalleryEntry: Identifiable, Codable {
    var id: Int { mentor.id }
    let mentor: Mentor
    var grade: CardGrade
    var isUnlocked: Bool
}

// MARK: - Challenge Tier

enum ChallengeTier: Int, CaseIterable, Identifiable, Codable {
    case tier1 = 1, tier2 = 2, tier3 = 3

    var id: Int { rawValue }

    var cardRewardCount: Int {
        switch self {
        case .tier1: return 1
        case .tier2: return 2
        case .tier3: return 3
        }
    }

    var dropRates: (commonRate: Double, epicRate: Double, legendaryRate: Double) {
        switch self {
        case .tier1: return (0.94, 0.05, 0.01)
        case .tier2: return (0.85, 0.12, 0.03)
        case .tier3: return (0.85, 0.10, 0.05)
        }
    }

    var guaranteedEpic: Bool { self == .tier3 }

    var description: String {
        switch self {
        case .tier1: return "1 Easy"
        case .tier2: return "2 Medium"
        case .tier3: return "3 Hard"
        }
    }
    
    var criteria: String {
        switch self {
            case .tier1: return "Answer 1 question"
            case .tier2: return "Answer at least 2 question"
            case .tier3: return "Answer 3 question in a row"
        }
    }
    
    var chances: String {
        switch self {
        case .tier1: return "94% Common, 5% Epic, 1% Legendary"
        case .tier2: return "85% Common, 12% Epic, 3% Legendary"
        case .tier3: return "1 Guaranteed Epic \n 85% Common, 10% Epic, 5% Legendary"
        }
    }

    var packColor: Color {
        switch self {
        case .tier1: return Color(hex: "#A7E2FF")
        case .tier2: return Color(hex: "#800000")
        case .tier3: return Color(hex: "#FFD700")
        }
    }

    var packLabel: String {
        switch self {
        case .tier1: return "Starter Pack"
        case .tier2: return "Pro Pack"
        case .tier3: return "Legendary Pack"
        }
    }

    var packEmoji: String {
        switch self {
        case .tier1: return "📦"
        case .tier2: return "🎁"
        case .tier3: return "⚡️"
        }
    }
}

// MARK: - Challenge Path

enum ChallengePath: String, CaseIterable {
    case brain = "BRAIN"

    var emoji: String {
        switch self {
        case .brain: return "🧠"
        }
    }

    var description: String {
        switch self {
        case .brain: return "Answer trivia questions"
        }
    }
}

// MARK: - Exercise Type

enum ExerciseType: String, CaseIterable {
    case bicepCurls = "Bicep Curls"
    case squats = "Squats"
}

// MARK: - Quiz Question

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let category: String
    let tier: Int
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Sample Mentor Data

extension Mentor {
    static let sampleData: [Mentor] = [
        Mentor(id: 1, name: "Alex Rivera", role: "iOS Engineer", career: "Senior Engineer at Apple", education: "BS Computer Science, MIT", hobby: "Bouldering", funFact: "Once shipped a feature used by 200M users overnight.", photoSystemName: "person.fill", accentColor: "#A7E2FF"),
        Mentor(id: 2, name: "Priya Sharma", role: "ML Researcher", career: "Research Scientist at DeepMind", education: "PhD Machine Learning, Stanford", hobby: "Classical Piano", funFact: "Published her first paper at age 19.", photoSystemName: "person.fill", accentColor: "#FFF39D"),
        Mentor(id: 3, name: "Jordan Kim", role: "Product Designer", career: "Principal Designer at Figma", education: "BFA Interaction Design, RISD", hobby: "Ceramics", funFact: "Designed the icon used by 15M daily users.", photoSystemName: "person.fill", accentColor: "#D4B8FF"),
        Mentor(id: 4, name: "Marcus Chen", role: "Backend Engineer", career: "Staff Engineer at Stripe", education: "BS Software Engineering, CMU", hobby: "Competitive Chess", funFact: "Handles 1M transactions per second in production.", photoSystemName: "person.fill", accentColor: "#B8FFD4"),
        Mentor(id: 5, name: "Sofia Torres", role: "Data Scientist", career: "Lead Data Scientist at Spotify", education: "MS Statistics, Columbia", hobby: "Salsa Dancing", funFact: "Her algorithms recommend music to 600M listeners.", photoSystemName: "person.fill", accentColor: "#FFB8C6"),
        Mentor(id: 6, name: "Liam O'Brien", role: "Security Engineer", career: "Principal Engineer at Cloudflare", education: "BS Cybersecurity, Purdue", hobby: "Rock Climbing", funFact: "Blocked the largest DDoS attack in history.", photoSystemName: "person.fill", accentColor: "#FFD4B8"),
        Mentor(id: 7, name: "Yuki Tanaka", role: "DevOps Lead", career: "SRE Lead at Google", education: "MS Computer Engineering, Keio", hobby: "Origami", funFact: "Reduced company infra cost by $4M in one year.", photoSystemName: "person.fill", accentColor: "#A7E2FF"),
        Mentor(id: 8, name: "Amara Osei", role: "Frontend Engineer", career: "Senior Engineer at Vercel", education: "BS Computer Science, Ghana Tech", hobby: "Street Photography", funFact: "Open source projects with 50k+ GitHub stars.", photoSystemName: "person.fill", accentColor: "#FFF39D"),
        Mentor(id: 9, name: "Diego Reyes", role: "Mobile Architect", career: "Staff Engineer at Uber", education: "MS Software Engineering, Georgia Tech", hobby: "Surfing", funFact: "Built the real-time GPS system in the Uber driver app.", photoSystemName: "person.fill", accentColor: "#D4B8FF"),
        Mentor(id: 10, name: "Emma Larsson", role: "AI Ethics Lead", career: "Director at Anthropic", education: "PhD Philosophy, Oxford", hobby: "Long-distance Running", funFact: "Advises 3 governments on AI regulation.", photoSystemName: "person.fill", accentColor: "#B8FFD4"),
        Mentor(id: 11, name: "Raj Patel", role: "Blockchain Developer", career: "Core Dev at Ethereum Foundation", education: "BS Mathematics, IIT Bombay", hobby: "Astronomy", funFact: "Wrote the ERC-721 NFT standard implementation.", photoSystemName: "person.fill", accentColor: "#FFB8C6"),
        Mentor(id: 12, name: "Chloe Dubois", role: "UX Researcher", career: "Principal Researcher at Meta", education: "MA Cognitive Science, Sorbonne", hobby: "Improv Theatre", funFact: "Her research reshaped Facebook's news feed algorithm.", photoSystemName: "person.fill", accentColor: "#FFD4B8"),
        Mentor(id: 13, name: "Kwame Mensah", role: "Systems Engineer", career: "Kernel Engineer at Linux Foundation", education: "BS Computer Engineering, UCT", hobby: "Jazz Drumming", funFact: "His kernel patch is in every Android phone.", photoSystemName: "person.fill", accentColor: "#A7E2FF"),
        Mentor(id: 14, name: "Hana Yoshida", role: "AR/VR Developer", career: "Vision Engineer at Apple", education: "MS Human-Computer Interaction, CMU", hobby: "Ikebana", funFact: "Shipped a key visionOS spatial computing feature.", photoSystemName: "person.fill", accentColor: "#FFF39D"),
        Mentor(id: 15, name: "Tyler Brooks", role: "Growth Engineer", career: "VP Engineering at Airbnb", education: "BS Economics, Yale", hobby: "Kitesurfing", funFact: "A/B tested his way to a $200M revenue uplift.", photoSystemName: "person.fill", accentColor: "#D4B8FF"),
        Mentor(id: 16, name: "Nadia Kowalski", role: "Compiler Engineer", career: "LLVM Contributor at NVIDIA", education: "PhD Computer Science, Warsaw", hobby: "Speed Cubing", funFact: "Her CUDA optimization made GPT-4 training 18% faster.", photoSystemName: "person.fill", accentColor: "#B8FFD4"),
        Mentor(id: 17, name: "Sam Washington", role: "Cloud Architect", career: "Fellow at AWS", education: "MS Distributed Systems, Berkeley", hobby: "Beekeeping", funFact: "Designed AWS's multi-region failover architecture.", photoSystemName: "person.fill", accentColor: "#FFB8C6"),
        Mentor(id: 18, name: "Fatima Al-Rashid", role: "Robotics Engineer", career: "Lead Engineer at Boston Dynamics", education: "PhD Robotics, ETH Zurich", hobby: "Parkour", funFact: "Programmed Atlas's backflip sequence.", photoSystemName: "person.fill", accentColor: "#FFD4B8"),
    ]
}
