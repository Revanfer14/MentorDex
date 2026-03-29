//
//  AudioManager.swift
//  MentorDex
//
//  Created by Revan Ferdinand on 25/03/26.
//

import SwiftUI
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    //    var player: AVAudioPlayer?
    var bgmPlayers: [String: AVAudioPlayer] = [:]
    var currentBGM: String? = nil
    var sfxPlayer: [String: AVAudioPlayer] = [:]
    
    @Published var isMuted: Bool = UserDefaults.standard.bool(forKey: "isMusicMuted") {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "isMusicMuted")
            
            // Atur playback pada lagu yang sedang aktif
            if let current = currentBGM, let activePlayer = bgmPlayers[current] {
                if isMuted {
                    activePlayer.pause()
                } else {
                    activePlayer.play()
                }
            }
        }
    }
    
    private init() {} // Mencegah inisialisasi ganda
    
    func startBackgroundMusic(filename: String, ext: String = "mp3") {
        playBGM(filename: "main-bgm")
    }
    
    func stopBGM() {
        if let current = currentBGM, let activePlayer = bgmPlayers[current] {
            activePlayer.stop()
            activePlayer.currentTime = 0 // Reset ke awal jika diputar lagi nanti
        }
        currentBGM = nil
    }
    
    func playBGM(filename: String, ext: String = "mp3", forcePlay: Bool = false) {
        if currentBGM == filename {
            let activePlayer = bgmPlayers[filename]
            
            if activePlayer?.isPlaying == true {
                return
            }
        }
        
        if let current = currentBGM, let activePlayer = bgmPlayers[current] {
            activePlayer.pause()
        }
        
        if bgmPlayers[filename] == nil {
            guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
                print("File BGM tidak ditemukan: \(filename).\(ext)")
                return
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.numberOfLoops = -1 //
                newPlayer.prepareToPlay()
                
                bgmPlayers[filename] = newPlayer
            } catch {
                print("Error ganti BGM: \(error.localizedDescription)")
                return
            }
        }
        
        currentBGM = filename
        if !isMuted || forcePlay {
            bgmPlayers[filename]?.play()
        }
    }
    
    func toggleMusic() {
        // Balikkan state dari true ke false, atau false ke true
        isMuted.toggle()
    }
    
    // MARK: - Sound Effects (SFX)
    func playSFX(filename: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("File SFX tidak ditemukan: \(filename).\(ext)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            // Simpan player ke dictionary agar tidak langsung terhapus dari memori sebelum bunyinya selesai
            sfxPlayer[filename] = player
            player.play()
        } catch {
            print("Error memutar SFX: \(error.localizedDescription)")
        }
    }
}

// Biar tinggal panggil playSound()
func playSound(_ file: String) {
    AudioManager.shared.playSFX(filename: file)
}

func playMusic(_ file: String, _ forcePlay: Bool) {
    AudioManager.shared.playBGM(filename: file, forcePlay: forcePlay)
}

// Fungsi Global untuk Getaran Maksimal
func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy, intensity: CGFloat = 1.0) {
    let generator = UIImpactFeedbackGenerator(style: style)
    
    generator.prepare()
    generator.impactOccurred(intensity: intensity)
}

// Fungsi Global untuk Haptic Notifikasi (Success/Error)
func playNotificationHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(type)
}
