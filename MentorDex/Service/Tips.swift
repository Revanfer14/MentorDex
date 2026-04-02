import Foundation
import SwiftUI
import TipKit

// MARK: - 1. Quiz Tip
struct QuizTip: Tip {
    var title: Text { Text("1. Earn Coins!") }
    var message: Text? { Text("Play the trivia quiz to earn coins. Get up to 50 coins for a perfect score!") }
    var image: Image? { Image(systemName: "brain.head.profile") }
    
    // Tombol Pseudo "Next"
    var actions: [Action] { [Action(id: "next", title: "Next: Shop")] }
    
    // GEMBOK: Hanya muncul jika Disclaimer sudah ditutup
    @Parameter static var isDisclaimerClosed: Bool = false
    var rules: [Rule] { #Rule(Self.$isDisclaimerClosed) { $0 == true } }
}

// MARK: - 2. Shop Tip
struct ShopTip: Tip {
    var title: Text { Text("2. Buy Packs") }
    var message: Text? { Text("Spend your hard-earned coins here to get new mentor cards.") }
    var image: Image? { Image(systemName: "cart.fill") }
    
    // Tombol Pseudo "Next"
    var actions: [Action] { [Action(id: "next", title: "Next: Inventory")] }
    
    // GEMBOK: Hanya muncul jika QuizTip sudah di-Next
    @Parameter static var isQuizTipDone: Bool = false
    var rules: [Rule] { #Rule(Self.$isQuizTipDone) { $0 == true } }
}

// MARK: - 3. Inventory Tip
struct InventoryTip: Tip {
    var title: Text { Text("3. Open Your Packs") }
    var message: Text? { Text("Packs you buy are stashed here. Tap one to tear it open!") }
    var image: Image? { Image(systemName: "shippingbox.fill") }
    
    // Tombol Selesai
    var actions: [Action] { [Action(id: "finish", title: "Got it!")] }
    
    // GEMBOK: Hanya muncul jika ShopTip sudah di-Next
    @Parameter static var isShopTipDone: Bool = false
    var rules: [Rule] { #Rule(Self.$isShopTipDone) { $0 == true } }
}

// MARK: - 4. Gallery Tip (Bebas, karena di tab berbeda)
struct GalleryTip: Tip {
    var title: Text { Text("View Collection") }
    var message: Text? { Text("Check out all the mentor cards you've collected and upgraded.") }
    var image: Image? { Image(systemName: "square.grid.2x2.fill") }
}
