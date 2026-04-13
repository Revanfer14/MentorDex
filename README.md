# MentorDex

> **Collect the cards. Connect with the mentors.**

MentorDex is a Pokémon-inspired iOS card-collecting app built for the **Apple Developer Academy**. Complete trivia challenges to earn booster packs, reveal holographic mentor cards, and build your collection — all powered by Apple Intelligence on-device AI.

---

## Features

- Coin Economy & Shop — Earn coins exponentially through 5-round trivia sessions to purchase booster packs.
- Gacha Pack System — Three tiers of packs (Starter, Pro, Legendary) with balanced drop rates and guaranteed Epic slots.
- Hybrid Trivia Engine — Dynamic questions combining on-device AI (FoundationModels), native math algorithms, and local Academy lore.
- 3D Pack Unboxing — Swipe-to-tear pack opening animation with a SceneKit (SCNView) 3D model.
- Holographic Cards — Epic & Legendary cards feature a CoreMotion-driven gyroscope hologram effect with colorDodge blend mode.
- Card Gallery — 60 collectible cards (20 mentors × 3 grades) with duplicate-upgrade logic.
- Pack Inventory (Stash) — Save purchased packs to open later; persisted via UserDefaults.
- Immersive Experience — Looping BGM (AVAudioPlayer), haptic feedback, custom confirmation pop-ups, and an animated Splash Screen.

---

## Project Structure

```
MentorDex/
├── MentorDexApp.swift          # App entry point
├── Info.plist                  
├── Model/
│   └── Models.swift            # Model
│   └── QuestionBank.swift      # Apple Academy's question bank
├── ViewModel/
│   └── GameState.swift         # Game logic
├── Service/
│   └── AudioManager.swift      # AVAudioPlayer
│   └── Tips.swift              # TipKit
├── Component/
│   └── MentorCardFront.swift   # Card component
└── Views/
    ├── SplashView.swift         # Animated launch screen
    ├── DashboardView.swift      # Home screen
    ├── GalleryView.swift        # Gallery screen
    ├── BrainChallengeView.swift # Quiz sheet
    └── PackOpeningView.swift    # Pack opening screen
```

---

## Card Grades & Drop Rates

| Tier | Pack | Cards | Common | Epic | Legendary | Special |
|------|------|-------|--------|------|-----------|---------|
| 1 | Starter Pack | 1 | 89% | 10% | 1% | — |
| 2 | Pro Pack | 2 | 82% | 15% | 3% | — |
| 3 | Legendary Pack | 3 | 85% | 10% | 5% | 1 Guaranteed Epic |

> ⚠️ **Disclaimer:** The Common, Epic, and Legendary tiers purely represent in-game card rarity and are **NOT** intended to evaluate or rank the mentors' real-life performance.

---

## Questions

Questions are generated on-device via **Apple Intelligence** (`LanguageModelSession`) with a structured `@Generable` schema. Native Swift math is used as a fast fallback category.

There are 3 types of question:
- General (basic knowledge)
- Math
- Apple Academy

There will be 5 Questions in total
- 1 Correct Answer = 2 Coins
- 2 Correct Answer = 4 Coins
- 3 Correct Answer = 8 Coins
- 4 Correct Answer = 10 Coins
- 5 Correct Answer = 15 Coins

---

## Requirements

- **iOS 26.0+** (required for `FoundationModels` / Apple Intelligence)
- **Xcode 26+**
- A physical iPhone device is recommended for:
  - CoreMotion gyroscope hologram effect
  - Apple Intelligence on-device model

---

## Assets

### Mentor Photos
All mentor portrait images are sourced from open platforms (mostly [Linkedin](https://linkedin.com)) and are used for educational, non-commercial purposes within the Academy context.

### Logo & Pack Images
The MentorDex logo and pack preview images are **AI-generated**.

### 3D Pack Model
The booster pack 3D model (`.usdz`) is a free asset by **Ben Abode**:
> [Ben's Booster Pack — Gumroad](https://benabode.gumroad.com/l/bensboosterpack)

### Typography
- **Fredoka** (Regular, SemiBold, Bold) — included as custom font via `Info.plist`

### Background Music & Sound Effects
- Background musics & sound effects are from open source websites (mostly [Pixabay](https://pixabay.com/))

---

## Legal & Copyright Disclaimer

**MentorDex** is an educational, non-commercial student project. It is strictly built for learning, portfolio demonstration, and internal community engagement.

This project draws heavy visual and conceptual inspiration from existing intellectual properties:
* **Pokémon, Pikachu, Poké Ball, and the Pokédex concept** are registered trademarks and copyrights of Nintendo, Creatures Inc., and GAME FREAK inc.
* The **Apple Logo** is a registered trademark of Apple Inc.

**No copyright infringement is intended.** This project is not affiliated with, endorsed, sponsored, or specifically approved by Nintendo, The Pokémon Company, or Apple Inc. Absolutely no financial profit is generated from this application. All original rights to the characters, designs, and names belong to their respective intellectual property owners.

*If you are the copyright holder of any intellectual property used in this repository and wish for its removal, please contact me, and the requested content will be taken down immediately.*

## License

This project is for educational purposes within the Apple Developer Academy program. All third-party assets retain their original licenses — see individual asset sources above.
