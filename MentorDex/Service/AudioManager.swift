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
    var player: AVAudioPlayer?
    
    @Published var isMuted: Bool = UserDefaults.standard.bool(forKey: "isMusicMuted") {
            didSet {
                // Simpan status terbaru ke memori HP setiap kali berubah
                UserDefaults.standard.set(isMuted, forKey: "isMusicMuted")
                
                // Atur playback
                if isMuted {
                    player?.pause()
                } else {
                    player?.play()
                }
            }
        }
        
    private init() {} // Mencegah inisialisasi ganda
    
    func startBackgroundMusic(filename: String, ext: String = "mp3") {
        guard player == nil else { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("❌ File musik tidak ditemukan! Pastikan namanya benar.")
            return
        }
        
        do {
            // Setting agar musik tidak mematikan audio dari aplikasi lain (seperti Spotify) jika tidak perlu,
            // atau set ke playback agar tetap jalan saat mode silent.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // -1 artinya Loop tanpa batas (Infinite)
            player?.prepareToPlay()
            
            if !isMuted {
                player?.play()
            }
        } catch {
            print("❌ Error memutar musik: \(error.localizedDescription)")
        }
    }
    
    func toggleMusic() {
        // Balikkan state dari true ke false, atau false ke true
        isMuted.toggle()
    }
}
