// GameState.swift
// MentorDex — Central App State (ObservableObject)
//
//  Created by Revan Ferdinand on 25/03/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {
    @Published var gallery: [GalleryEntry] = []
    @Published var pendingRewardCards: [RewardCard] = []
    @Published var isShowingPackOpening: Bool = false
    @Published var currentTab: AppTab = .dashboard
    @Published var unopenedPacks: [ChallengeTier] = []
    @Published var coins: Int = 0

    // MARK: - Computed

    var unlockedCount: Int { gallery.filter { $0.isUnlocked }.count }
    var totalCards: Int { 60 }

    // MARK: - Init

    init() {
        setupGallery()
        loadSavedState()
    }

    private func setupGallery() {
        gallery = Mentor.sampleData.map { mentor in
            GalleryEntry(mentor: mentor, grade: .common, isUnlocked: false)
        }
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
        saveState()
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if(coins >= amount) {
            coins -= amount
            saveState()
            return true
        }
        return false
    }

    // MARK: - Pack Management & Reward Distribution

    struct RewardCard: Identifiable {
        let id = UUID()
        let mentor: Mentor
        let grade: CardGrade
        var isNew: Bool = true
    }
    
    func savePackToInventory(tier: ChallengeTier) {
        unopenedPacks.append(tier)
        saveState()
    }
    
    func removePackFromInventory(tier: ChallengeTier) {
            if let index = unopenedPacks.firstIndex(of: tier) {
                unopenedPacks.remove(at: index)
                saveState()
            }
        }

    func openPack(tier: ChallengeTier) -> [RewardCard] {
        var rewards: [RewardCard] = []
        let allMentors = Mentor.sampleData
        
        let count: Int
        let guaranteedEpic: Bool

        switch tier {
                case .tier1:
                    count = tier.cardRewardCount
                    guaranteedEpic = false
                case .tier2:
                    count = tier.cardRewardCount
                    guaranteedEpic = false
                case .tier3:
                    count = tier.cardRewardCount
                    guaranteedEpic = true
                }

        for i in 0..<count {
            let grade: CardGrade
            
            if guaranteedEpic && i == 0 {
                let roll = Double.random(in: 0...1)
                grade = roll < 0.95 ? .epic : .legendary
            } else {
                grade = drawGrade(for: tier)
            }
            
            let mentor = allMentors.randomElement()!
            let reward = RewardCard(mentor: mentor, grade: grade)
            rewards.append(reward)
        }

        for reward in rewards { applyReward(reward) }
        return rewards
    }
    
    // MARK: - Gacha Probability Logic
    private func drawGrade(for tier: ChallengeTier) -> CardGrade {
        let roll = Double.random(in: 0...1)
        
        let commonRate: Double
        let epicRate: Double
        
        switch tier {
        case .tier1:
            commonRate = 0.92
            epicRate = 0.07
        case .tier2:
            commonRate = 0.85
            epicRate = 0.12
        case .tier3:
            commonRate = 0.73
            epicRate = 0.22
        }
        
        if roll < commonRate {
            return .common
        } else if roll < (commonRate + epicRate) {
            return .epic
        } else {
            return .legendary
        }
    }

    private func applyReward(_ reward: RewardCard) {
        guard let idx = gallery.firstIndex(where: { $0.mentor.id == reward.mentor.id }) else { return }
        let existing = gallery[idx]

        if !existing.isUnlocked {
            gallery[idx] = GalleryEntry(mentor: existing.mentor, grade: reward.grade, isUnlocked: true)
        } else {
            let isUpgradeToEpic = existing.grade == .common && reward.grade == .epic
            let isUpgradeToLegendary = (existing.grade == .common || existing.grade == .epic) && reward.grade == .legendary
            
            if isUpgradeToLegendary {
                gallery[idx] = GalleryEntry(mentor: existing.mentor, grade: .legendary, isUnlocked: true)
            } else if isUpgradeToEpic {
                gallery[idx] = GalleryEntry(mentor: existing.mentor, grade: .epic, isUnlocked: true)
            }
        }
        saveState()
    }

    // MARK: - Persistence (UserDefaults)

    private let galleryKey = "gallery_v2"
    private let packsKey = "unopened_packs_v1" // Key untuk simpan inventory
    private let coinsKey = "user_coins_v1"

    func saveState() {
        if let encoded = try? JSONEncoder().encode(gallery) {
            UserDefaults.standard.set(encoded, forKey: galleryKey)
        }
        if let encodedPacks = try? JSONEncoder().encode(unopenedPacks) {
            UserDefaults.standard.set(encodedPacks, forKey: packsKey)
        }
        
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }

    func loadSavedState() {
        if let data = UserDefaults.standard.data(forKey: galleryKey),
           let decoded = try? JSONDecoder().decode([GalleryEntry].self, from: data) {
            for saved in decoded {
                if let idx = gallery.firstIndex(where: { $0.mentor.id == saved.mentor.id }) {
                    gallery[idx] = saved
                }
            }
        }
        if let packData = UserDefaults.standard.data(forKey: packsKey),
           let decodedPacks = try? JSONDecoder().decode([ChallengeTier].self, from: packData) {
            unopenedPacks = decodedPacks
        }
        
        coins = UserDefaults.standard.integer(forKey: coinsKey)
    }
}

// MARK: - App Tabs
enum AppTab: String, CaseIterable {
    case dashboard = "Home"
    case gallery = "Gallery"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .gallery: return "square.grid.2x2.fill"
        }
    }
}
