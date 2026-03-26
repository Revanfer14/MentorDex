// GameState.swift
// MentorDex — Central App State (ObservableObject)

import Foundation
import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {

    // MARK: - Published State

    @Published var gallery: [GalleryEntry] = []
    @Published var pendingRewardCards: [RewardCard] = []
    @Published var isShowingPackOpening: Bool = false
    @Published var currentTab: AppTab = .dashboard
    
    // 🌟 NEW: Inventory Sistem untuk menabung Pack
    @Published var unopenedPacks: [ChallengeTier] = []

    // MARK: - Computed

    var unlockedCount: Int { gallery.filter { $0.isUnlocked }.count }
    var totalCards: Int { 54 } // 18 mentors × 3 grades

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

    func distributeRewards(tier: ChallengeTier) -> [RewardCard] {
        var rewards: [RewardCard] = []
        let count = tier.cardRewardCount
        let allMentors = Mentor.sampleData

        for i in 0..<count {
            let grade: CardGrade
            
            // Aturan khusus Tier 3: Kartu pertama DIJAMIN Epic (Atau Legendary kalau mau berbaik hati, tapi kita set Epic pasti)
            if tier.guaranteedEpic && i == 0 {
                grade = .epic
            } else {
                // Sisa kartu diundi berdasarkan probabilitas tier
                grade = drawGrade(for: tier)
            }
            
            let mentor = allMentors.randomElement()!
            let reward = RewardCard(mentor: mentor, grade: grade)
            rewards.append(reward)
        }

        // Apply to gallery
        for reward in rewards { applyReward(reward) }
        return rewards
    }
    
    // MARK: - Gacha Probability Logic
    private func drawGrade(for tier: ChallengeTier) -> CardGrade {
        let roll = Double.random(in: 0...1)
        let rates = tier.dropRates
        
        if roll < rates.commonRate {
            return .common
        } else if roll < (rates.commonRate + rates.epicRate) {
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
    private let packsKey = "unopened_packs_v1" // 🌟 Key untuk simpan inventory

    func saveState() {
        if let encoded = try? JSONEncoder().encode(gallery) {
            UserDefaults.standard.set(encoded, forKey: galleryKey)
        }
        if let encodedPacks = try? JSONEncoder().encode(unopenedPacks) {
            UserDefaults.standard.set(encodedPacks, forKey: packsKey)
        }
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
