import Foundation

/// Copy added with the Christmas redesign. Kept in one place so TR / EN
/// stay side by side; the active language is derived from the base table.
extension Strings {
    private var isTR: Bool { loginBtn == Strings.tr.loginBtn }
    private func l(_ tr: String, _ en: String) -> String { isTR ? tr : en }

    // Onboarding & auth
    var happyNewYear: String { l("Mutlu Yıllar", "Happy Holidays") }
    var onbTitle: String { l("Yılbaşı çekilişi cebinde", "Secret Santa in your pocket") }
    var onbBody: String { l("Herkes adil şekilde eşleşsin, sürpriz son ana kadar saklı kalsın.", "Everyone gets a fair match and the surprise stays secret until the very end.") }
    var emailShort: String { l("E-posta ile", "With e-mail") }
    var joinWithCode: String { l("Kodla katıl", "Join with code") }
    var google: String { l("Google ile devam et", "Continue with Google") }
    var appleContinue: String { l("Apple ile devam et", "Continue with Apple") }
    var googleSoon: String { l("Google ile giriş çok yakında aktif olacak.", "Google sign-in is coming soon.") }
    var welcome: String { l("Hoş geldin!", "Welcome!") }
    var welcomeSub: String { l("Adını Noel Baba'nın listesine yazdır.", "Get your name on Santa's list.") }
    var notLooking: String { l("Bakmıyorum!", "Not peeking!") }
    var tryWithoutAccount: String { l("Hesap açmadan dene:", "Try without an account:") }
    var manualDraw: String { l("Manuel çekiliş", "Manual draw") }

    // Home
    var hello: String { l("Merhaba", "Hello") }
    var myDraws: String { l("Çekilişlerim", "My draws") }
    var nextDraw: String { l("Sıradaki çekiliş", "Next draw") }
    var allEvents: String { l("Tüm etkinlikler", "All events") }
    var activeCount: String { l("%d aktif", "%d active") }
    var daysUnit: String { l("gün", "days") }
    var hoursUnit: String { l("saat", "hours") }
    var minutesUnit: String { l("dakika", "min") }

    // New draw
    var newSurprise: String { l("Yeni bir sürpriz?", "A new surprise?") }
    var howToDraw: String { l("Nasıl çekelim?", "How shall we draw?") }
    var inviteModeTitle: String { l("Davet Modu", "Invite Mode") }
    var manualModeTitle: String { l("Manuel Modu", "Manual Mode") }
    var inviteSteps: [String] { isTR
        ? ["Tarihi ve saati seç", "Davet linkini grupla paylaş", "Eşleşmeler bildirim ve e-postayla gitsin"]
        : ["Pick the date and time", "Share the invite link", "Matches go out by push and e-mail"] }
    var manualSteps: [String] { isTR
        ? ["Katılımcıları ekle (en az 3)", "Çekiliş düğmesine bas", "Eşleşmeler e-postayla gitsin"]
        : ["Add participants (at least 3)", "Tap the draw button", "Matches go out by e-mail"] }
    var inviteCta: String { l("Davet linki oluştur", "Create invite link") }
    var manualCta: String { l("Manuel çekilişe başla", "Start a manual draw") }
    var manualEmailNote: String { l("Eşleşmeler herkese e-postayla gönderilir.", "Matches are e-mailed to everyone.") }

    // Drawing / join
    var santaDrawing: String { l("Noel Baba torbadan çekiyor…", "Santa is drawing from the sack…") }
    var shuffling: String { l("Eşleşmeler karıştırılıyor, kimse kendini çekmeyecek.", "Shuffling matches — nobody draws themselves.") }
    var allReady: String { l("Hepsi hazır!", "All set!") }
    var matchesSent: String { l("Herkese bildirim ve e-posta gitti.", "Everyone got a push and an e-mail.") }
    var haveInvite: String { l("Davetin var mı?", "Got an invite?") }
    var haveInviteSub: String { l("Kodu gir, Noel Baba seni listeye eklesin.", "Enter the code and Santa adds you to the list.") }
    var inviteCodeLabel: String { l("Davet kodu", "Invite code") }
    var inviteCodeHint: String { l("Örnek: ABC123 · Harf ve rakamlardan oluşur.", "Example: ABC123 · letters and numbers.") }
    var youreInvited: String { l("Davetlisin!", "You're invited!") }
    var congrats: String { l("Tebrikler!", "Congrats!") }
    var continueLabel: String { l("Devam et", "Continue") }
}
