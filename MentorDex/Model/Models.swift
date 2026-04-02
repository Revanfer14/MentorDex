//
//  Models.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import Foundation
import SwiftUI

// MARK: - Mentor Model

struct Mentor: Identifiable, Codable, Equatable {
    let id: Int
    let nickname: String
    let name: String
    let role: String
    let career: String
    let education: [String]
    let hobby: [String]
    let funFact: [String]
    let mentorImage: String
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
        case .tier1: return 4
        case .tier2: return 7
        case .tier3: return 10
        }
    }
    
    var dropRates: (commonRate: Double, epicRate: Double, legendaryRate: Double) {
        switch self {
        case .tier1: return (0.89, 0.10, 0.01)
        case .tier2: return (0.82, 0.15, 0.03)
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
        case .tier1: return "92% Common, 7% Epic, 1% Legendary"
                case .tier2: return "80% Common, 17% Epic, 3% Legendary"
                case .tier3: return "1 Guaranteed Epic/Legendary\n70% Common, 25% Epic, 5% Legendary"
        }
    }
    
    var packColor: Color {
        switch self {
        case .tier1: return Color.starterpack
        case .tier2: return Color.propack
        case .tier3: return Color.legendpack
        }
    }
    
    var packPrice: Int {
        switch self {
        case .tier1: return 10
        case .tier2: return 20
        case .tier3: return 35
        }
    }
    
    var packLabel: String {
        switch self {
        case .tier1: return "Starter Pack"
        case .tier2: return "Pro Pack"
        case .tier3: return "Legendary Pack"
        }
    }
    
    var packImage: String {
        switch self {
        case .tier1: return "pack_preview_1"
        case .tier2: return "pack_preview_2"
        case .tier3: return "pack_preview_3"
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
        Mentor(id: 1, nickname: "Ko Har", name: "Haryanto Salim", role: "Tech Mentor", career: "Tech Mentor for 8 years 2 months", education: ["S1 Binus University", "S2 Swiss German University (on going)"], hobby: ["Martial Art", "Drawing"], funFact: ["Won some gold medals in university level and silver medals after 30s (Martial Arts)"], mentorImage: "kohar", accentColor: "#A7E2FF"),
        
        Mentor(id: 2, nickname: "Ko Jacob", name: "Jacob Andrean", role: "Tech Mentor", career: "Ex iOS Developer at Gojek, Accenture, LPS, Bank Saham, Group Avows", education: ["S1 Universitas Tarumanagara"], hobby: ["Coding"], funFact: ["Punya doggy suka ngempeng", "Loves new technology / invention"], mentorImage: "kojacob", accentColor: "#FFF39D"),
        
        Mentor(id: 3, nickname: "Ci Jes", name: "Jessi Febria", role: "Tech Mentor", career: "Ex Software Engineer (iOS) at Traveloka", education: ["S1 Universitas Kristen Satya Wacana"], hobby: ["Binge Watching"], funFact: ["Once a star seller at Shopee with 200k+ products sold", "Alumni of ADA Cohort 4", "Co-Founder of PetaNetra"], mentorImage: "cijes", accentColor: "#D4B8FF"),
        
        Mentor(id: 4, nickname: "Ka Rima", name: "Karima Yulia", role: "Design Mentor", career: "Ex Senior Visual Designer at Traveloka", education: ["S1 Institut Teknologi Bandung", "S2 Monash University"], hobby: ["Reading books", "Playing cozy game"], funFact: ["Hafal lagu pop tahun 90an", "Balkon apart paling hijau se-antero Casa de Parco"], mentorImage: "karima", accentColor: "#B8FFD4"),
        
        Mentor(id: 5, nickname: "Ka Khoi", name: "Khoirunnisa Rizky Noor Fatimah", role: "Tech Mentor", career: "Tech Mentor for 6 years", education: ["S1 Universitas Gadjah Mada", "S2 Monash University"], hobby: ["Tennis", "Archery"], funFact: ["Used to be Javanese/Kpop dancer", "Alumni of ADA Cohort 2", "Co-Founder of Qiroah"], mentorImage: "kakhoi", accentColor: "#FFB8C6"),
        
        Mentor(id: 6, nickname: "Ci Meicy", name: "Emery Meicy", role: "Design Mentor", career: "Ex Freelancer and Remote Worker", education: ["S1 Binus University", "Study abroad to Northumbira University for a year"], hobby: ["Cooking", "Crafting"], funFact: ["Like any kind of cuisine with tofu", "Easily distracted by sound"], mentorImage: "cimeicy", accentColor: "#FFD4B8"),
        
        Mentor(id: 7, nickname: "Ko Phil", name: "Phil Wira", role: "Co Head of Academy", career: "Ex Design Mentor in Apple Developer Academy", education: ["S1 Illinois Institute of Technology | (Architecture)"], hobby: ["Playing boardgame", "Volleyball"], funFact: ["Alergi cabe", "Suka keju padahal lactose intolerant", "Alumni of ADA Cohort 1"], mentorImage: "kophil", accentColor: "#A7E2FF"),
        
        Mentor(id: 8, nickname: "Ka Rizqi", name: "Rizqi Imam Gilang Widianto", role: "Tech Mentor", career: "Ex Project Manager & iOS Developer at Bank Mandiri", education: ["S1 Universitas Indonesia"], hobby: ["Main bola, futsal, mini soccer, fifa", "Baca buku"], funFact: ["Main Fifa dari 2006", "Suka banget secbowl", "Alumni of ADA Cohort 3"], mentorImage: "karizqi", accentColor: "#FFF39D"),
        
        Mentor(id: 9, nickname: "Ci Valen", name: "Valencia Gabriella", role: "Product & Growth Mentor", career: "Ex Product Manager at Traveloka & Brand Manager at Unilever", education: ["S1 The Hong Kong University of Science and Technology", "S2 University of Melbourne"], hobby: ["Creating contents", "Reading books", "Watching k-drama"], funFact: ["Pernah makan serangga", "Adrenaline junkie", "Founder of talentgo.ai"], mentorImage: "civalen", accentColor: "#D4B8FF"),
        
        Mentor(id: 10, nickname: "Ko Wilchris", name: "William Chrisandy", role: "Tech Mentor", career: "Ex Software Engineer at Samsung R&D Indonesia", education: ["S1 Binus University"], hobby: ["Listening to music", "Sleeping"], funFact: ["Top 0.001% listeners of Taylor Swift", "Suka kesandung / nabrak sendiri", "Alumni of ADA Cohort 5"], mentorImage: "kowilc", accentColor: "#B8FFD4"),
        
        Mentor(id: 11, nickname: "Ko Luq", name: "Luqman Adi Prasatya Hamaki", role: "Design Mentor", career: "Ex Copywriter at Blibli & Traveloka, Ex UX Writer at Bank Mandiri & GoTo Group", education: ["S1 Hunter College New York", "S2 Prasetiya Mulia"], hobby: ["Cycling", "Ngerakit plastic models (gundam, tamiya)"], funFact: ["Pernah bike tour keliling New York City", "Tinggal 13 tahun di New York dari SMA sampe kerja"], mentorImage: "koluq", accentColor: "#FFF39D"),
        
        Mentor(id: 12, nickname: "Ka Ica", name: "Anisa Nabila", role: "Co Head of Academy", career: "Ex Interaction Designer at Traveloka", education: ["S1 Institut Teknologi Bandung", "S2 University of Melbourne"], hobby: ["Trekking", "Travelling"], funFact: ["Panggilannya 'unyil' di rumah karena anak bungsu", "Pernah tenggelam di Pangandaran waktu kecil"], mentorImage: "kaica", accentColor: "#FFD4B8"),
        
        Mentor(id: 13, nickname: "Ko Hen", name: "Henri Jufry", role: "Product & Growth Mentor", career: "Ex Assistant to Resident Director at University of California", education: ["S1 - (Unknown)", "S2 University of South Australia"], hobby: ["Otomotif", "Olahraga"], funFact: ["Color Blind Partial", "Suka pake topi"], mentorImage: "kohen", accentColor: "#A7E2FF"),
        
        Mentor(id: 14, nickname: "Ko Wil", name: "William Sjahrial", role: "Product & Growth Mentor", career: "Ex Lecturer at Universitas Multimedia Nusantara, Ex Software Engineer at Mizuho (Japan), Ex iOS Developer at Mirai LLP (Japan)", education: ["S1 Georgia Institute of Technology"], hobby: ["Lego", "Gym", "Sports"], funFact: ["Suka main Street Fighter dulu", "Suka olahraga dan gym"], mentorImage: "kowil", accentColor: "#FFB8C6"),
        
        Mentor(id: 15, nickname: "Ka Ria", name: "Ria Chandra", role: "Design Mentor", career: "Ex Full Time Laboratory Assistant at Binus, Ex User Experience Designer & Researcher at Harian Kompas", education: ["S1 Binus University"], hobby: ["Suka main dan nonton", "Crafting"], funFact: ["Bisa bahasa arab dan lumayan banyak bahasa", "Pas kuliah, cuma ada 6 perempuan seangkatan"], mentorImage: "karia", accentColor: "#D4B8FF"),
        
        Mentor(id: 16, nickname: "Ka Afi", name: "Tsamara Alifia", role: "Design Mentor", career: "Ex Freelancer", education: ["S1 & S2 Institut Teknologi Bandung"], hobby: ["Main game", "Gym", "Baca komik"], funFact: ["A big potterhead, pernah nulis fanmail ke Daniel Radcliffe & Emma Watson dan dibales!", "Alumni of ADA Cohort 4", "WWDC 2021 Winner"], mentorImage: "kaafi", accentColor: "#B8FFD4"),
        
        Mentor(id: 17, nickname: "Ka Toya" , name: "Jazilul Athoya", role: "Tech Mentor", career: "Tech Mentor for 8 years 2 months", education: ["S1 Universitas Gadjah Mada", "S2 Seoul National University of Science and Technology"], hobby: ["TCG Pokemon", "Aquascape"], funFact: ["Chicken Farmer", "Coder tapi bisa ilustrasi"], mentorImage: "katoya", accentColor: "#FFB8C6"),
        
        Mentor(id: 18, nickname: "Ko Octa",name: "Octavianus Gandajaya", role: "Tech Mentor", career: "Tech Mentor for 9 years", education: ["S1 Binus University"], hobby: ["Console Gaming", "Discovering new tech"], funFact: ["Climbed Rinjani Mountain on 1st climbing", "Dived 15m deep on 1st diving"], mentorImage: "koocta", accentColor: "#FFD4B8"),
        
        Mentor(id: 19, nickname: "Ci Del" , name: "Delvina Janice", role: "Tech Mentor", career: "Ex iOS Engineer at Ajaib", education: ["(Unknown)"], hobby: ["Crochet", "Gaming"], funFact: ["Ex Ballerina", "Alumni of ADA Cohort 4"], mentorImage: "cidel", accentColor: "#FFB8C6"),
        
        Mentor(id: 20, nickname: "Ka Eko" , name: "Eko Cahyo Prihantoro", role: "Design Mentor", career: "Ex Interaction Designer at Traveloka", education: ["S1 Institut Teknologi Bandung"], hobby: ["Main Tamiya"], funFact: ["Mirip Praz Teguh", "Alumni of ADA Cohort 3"], mentorImage: "kaeko", accentColor: "#FFB8C6")
    ]
}

