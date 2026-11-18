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
    var privacyPolicy: String { l("Gizlilik Politikası", "Privacy Policy") }
    var termsOfUse: String { l("Kullanım Koşulları", "Terms of Use") }
    var legalPrefix: String { l("Devam ederek", "By continuing you agree to the") }
    var legalAnd: String { l("ve", "and") }
    var legalSuffix: String { l("metinlerini kabul etmiş olursun.", "") }
    var googleFailed: String { l("Google ile giriş tamamlanamadı, lütfen tekrar dene.", "Google sign-in could not be completed, please try again.") }
    var welcome: String { l("Hoş geldin!", "Welcome!") }
    var welcomeSub: String { l("Adını Noel Baba'nın listesine yazdır.", "Get your name on Santa's list.") }
    var notLooking: String { l("Bakmıyorum!", "Not peeking!") }
    var tryWithoutAccount: String { l("Hesap açmadan dene:", "Try without an account:") }
    var manualDraw: String { l("Manuel çekiliş", "Manual draw") }

    // New Year wishes: local notifications every other evening, kind words rather than ads ("{d}" = days left)
    var countdownSetting: String { l("Yeni yıl dilekleri", "New Year wishes") }
    var pushItem4: String { l("Yılbaşına kadar her akşam güzel dilekler", "Kind words every evening until New Year") }
    var countdownEveTitle: String { l("Mutlu yıllar! 🎆", "Happy New Year! 🎆") }
    var countdownEveBody: String { l("Yeni yılın umutla, sağlıkla ve sevdiklerinle dolu olsun. İyi ki varsın.", "May your new year be full of hope, health and the people you love. We're glad you're here.") }
    var countdownMessages: [(title: String, body: String)] {
        isTR ? [
            ("Yeni yıla {d} gün 🌱", "Bu yıl ne kadar zorlandıysan o kadar güçlendin. Kendine bunun için bir teşekkür et."),
            ("Küçük bir hatırlatma ✨", "Her şeyi bitirmek zorunda değilsin. Bugün yapabildiklerin de yeterli."),
            ("Bir nefes al 🕯️", "Yılın kalan {d} gününde kendine biraz yavaşlama izni ver."),
            ("Güzel şeyler yolda 🌟", "Yeni yıl, yeni bir sayfa demek. Kalem hâlâ senin elinde."),
            ("Kendine iyi bak 🤍", "Bugün sevdiğin birine bir mesaj at. Bazen iyi gelen tek şey kısa bir merhabadır."),
            ("Bu yıldan bir anı 📸", "Bu yıl seni gülümseten bir anı düşün. Yeni yıla onu da yanında götür."),
            ("Umut da bir alışkanlık ☀️", "Yarın için küçük bir şey dile. Büyük değişimler küçük dileklerle başlar."),
            ("Yeni yıla {d} gün ❄️", "Mükemmel olmak zorunda değilsin; olduğun hâlinle değerlisin."),
            ("Kendine bir söz ver 🌿", "Yeni yılda kendine biraz daha sabırlı ve şefkatli olacağına söz ver."),
            ("Paylaştıkça çoğalır 🎁", "En güzel hediye birine ayırdığın zaman. Bu hafta sevdiğin birine vakit ayır."),
            ("Hafifle 🍂", "Taşıması ağır gelenleri bu yılda bırakabilirsin. Yeni yıl hafif başlasın."),
            ("Gece en karanlıkken 🌙", "Sabah yakındır. Zor günler de geçer; sen onlardan daha güçlüsün."),
            ("Bugün için bir iyilik 🌼", "Bugün kendin için küçük bir iyilik yap: bir çay, kısa bir yürüyüş ya da sevdiğin bir şarkı."),
            ("Yeni yıla {d} gün 💫", "Geçen yıl bu zamanlar seni üzen şeylerin çoğu artık geride. Bugünküler de geçecek."),
            ("Minnet listesi 📝", "Bugün minnettar olduğun üç şeyi düşün. Küçük olmaları hiç sorun değil."),
            ("Yanında olanlar 💛", "Seni olduğun gibi seven insanlar var. Bugün onlardan birini hatırla."),
            ("Dinlenmek de bir adım 😴", "Durmak geride kalmak değildir. Bazen en iyi ilerleme biraz dinlenmektir."),
            ("Hayallerin seni bekliyor 🎈", "Ertelediğin o hayal için yeni yılda küçük bir adım at."),
            ("Yeni yıla {d} gün 🌸", "Kendinle konuşurken, en sevdiğin arkadaşınla konuşur gibi konuş."),
            ("Işığını kısma 🔆", "Varlığın birilerinin gününü aydınlatıyor, sen farkında olmasan bile."),
            ("Bir adım yeter 👣", "Bütün merdiveni görmek zorunda değilsin. İlk basamağa adım atman yeter."),
            ("Gülümse 😊", "Bugün seni gülümseten küçük bir şeyi fark et ve biraz daha uzun gülümse."),
            ("Kendine zaman tanı ⏳", "Bazı şeyler zaman ister. O zamanı kendine de tanı."),
            ("Yeni yıla {d} gün 🍀", "Şans biraz da cesaret demek. Yeni yılda kendine bir şans ver."),
        ] : [
            ("{d} days to the new year 🌱", "However hard this year was, it made you stronger. Take a moment to thank yourself."),
            ("A small reminder ✨", "You don't have to finish everything. What you managed today is enough."),
            ("Take a breath 🕯️", "Give yourself permission to slow down a little in the {d} days left this year."),
            ("Good things are coming 🌟", "A new year is a new page, and the pen is still in your hand."),
            ("Be gentle with yourself 🤍", "Send a message to someone you love today. Sometimes a simple hello is all it takes."),
            ("A memory from this year 📸", "Think of a moment that made you smile this year. Take it with you into the next one."),
            ("Hope is a habit ☀️", "Wish for one small thing for tomorrow. Big changes start with small wishes."),
            ("{d} days to the new year ❄️", "You don't have to be perfect. You are enough just as you are."),
            ("Make yourself a promise 🌿", "Promise to be a little more patient and kind with yourself next year."),
            ("It grows when shared 🎁", "The best gift is your time. Spend some with someone you love this week."),
            ("Travel light 🍂", "You can leave what feels heavy in this year. Let the new one start light."),
            ("When the night is darkest 🌙", "Morning is close. Hard days pass, and you are stronger than them."),
            ("A kindness for today 🌼", "Do something small and kind for yourself today: a cup of tea, a short walk or a favourite song."),
            ("{d} days to the new year 💫", "Most of what worried you this time last year is behind you now. Today's worries will pass too."),
            ("A gratitude list 📝", "Think of three things you're grateful for today. It's fine if they're small."),
            ("The people beside you 💛", "There are people who love you just as you are. Think of one of them today."),
            ("Rest is a step too 😴", "Pausing isn't falling behind. Sometimes the best progress is a little rest."),
            ("Your dreams are waiting 🎈", "Take one small step next year towards the dream you keep putting off."),
            ("{d} days to the new year 🌸", "Talk to yourself the way you'd talk to your best friend."),
            ("Don't dim your light 🔆", "You brighten someone's day just by being you, even when you don't notice."),
            ("One step is enough 👣", "You don't have to see the whole staircase. Just take the first step."),
            ("Smile 😊", "Notice one small thing that makes you smile today, and smile a little longer."),
            ("Give yourself time ⏳", "Some things take time. Give that time to yourself too."),
            ("{d} days to the new year 🍀", "Luck is partly courage. Give yourself a chance next year."),
        ]
    }
    var countdownFinal: [(title: String, body: String)] {
        isTR ? [
            ("Yeni yıla {d} gün kaldı 🎇", "Bu yıl nelere dayandığını hatırla. Yeni yılı fazlasıyla hak ediyorsun."),
            ("Bir dilek tut 🌠", "Yeni yıl için kalbinden geçen dileği bir kâğıda yaz ve sakla."),
            ("Teşekkür zamanı 🙏", "Öğrettikleri için bu yıla, dayandığın için kendine teşekkür et."),
        ] : [
            ("{d} days left 🎇", "Remember everything you got through this year. You more than deserve the new one."),
            ("Make a wish 🌠", "Write down the wish in your heart for the new year and keep it somewhere safe."),
            ("Time to say thank you 🙏", "Thank this year for what it taught you, and yourself for getting through it."),
        ]
    }

    // Local gift reminder (no names: a lock screen must not spoil the surprise)
    var giftReminderTitle: String { l("Yılbaşına 3 gün kaldı 🎁", "3 days until New Year's Eve 🎁") }
    var giftReminderBody: String { l("Hediyeni aldın mı? Kime alacağını görmek için dokun.", "Got your gift yet? Tap to see who you're buying for.") }

    // Reveal (same steps and copy as the website)
    var revealLoading: String { l("Sürprizin hazırlanıyor…", "Getting your surprise ready…") }
    var revealEyebrow: String { l("ÇEKİLİŞ YAPILDI!", "THE DRAW IS DONE!") }
    var revealHelloText: String { l("Bu yılbaşı birini çok mutlu edeceksin. Noel Baba senin için bir isim seçti, hazırsan başlayalım!", "This year you're going to make someone very happy. Santa picked a name just for you. Ready?") }
    var revealShow: String { l("Sürprizimi göster", "Show my surprise") }
    var revealSantaTitle: String { l("Noel Baba torbaya uzandı…", "Santa reaches into his sack…") }
    var revealSantaSearching: String { l("Bakalım kimin adını çekecek…", "Let's see whose name he draws…") }
    var revealSantaFound: String { l("Buldu! Senin için özel bir isim çekti 🎅", "Got it! He drew a special name just for you 🎅") }
    var revealBringGift: String { l("Hediyemi getir 🎁", "Bring my gift 🎁") }
    var revealGiftTitle: String { l("Hediyen burada!", "Your gift is here!") }
    var revealGiftText: String { l("Kimin hediyesini alacağın bu kutunun içinde.", "The person you're gifting is inside this box.") }
    var revealGiftOpening: String { l("Açılıyor…", "Opening…") }
    var revealGiftCta: String { l("Açmak için dokun", "Tap to open") }
    var revealResultEyebrow: String { l("Hediyesini alacağın kişi", "You're gifting") }
    var revealSecretNote: String { l("Unutma, bu bir sır! 🤫 Hediyeyi çekiliş günü sürpriz olarak ver.", "Remember, it's a secret! 🤫 Hand the gift over as a surprise on the day.") }
    var revealReplay: String { l("Baştan izle", "Watch again") }

    var loadingDraws: String { l("Etkinlikler yükleniyor…", "Loading draws…") }
    var loadingDraw: String { l("Çekiliş bilgileri yükleniyor…", "Loading draw information…") }

    // Invite sharing
    var shareMessage: String { l("🎅 Yılbaşı çekilişine davetlisin! Katılmak için bilgilerini doldur:", "🎅 You're invited to our Secret Santa! Fill in your details to join:") }
    var shareSubject: String { l("Yılbaşı çekilişine davetlisin 🎁", "You're invited to our Secret Santa 🎁") }
    var shareMessages: String { l("Mesaj", "Messages") }
    var shareMail: String { l("E-posta", "Mail") }
    var shareWhatsAppStatus: String { l("Durum", "Status") }
    var shareInstagramStory: String { l("Hikâye", "Story") }
    var sharePoster: String { l("Afiş", "Poster") }
    var posterScan: String { l("Kameranla okut", "Scan with your camera") }
    var posterStep1: String { l("QR kodu okut", "Scan the QR code") }
    var posterStep2: String { l("Bilgilerini doldur", "Fill in your details") }
    var posterStep3: String { l("Eşleşmeni öğren", "Find out your match") }
    var posterOr: String { l("ya da letsraffle.co'da bu kodu gir", "or enter this code at letsraffle.co") }
    var storyEyebrow: String { l("YILBAŞI ÇEKİLİŞİ", "SECRET SANTA") }
    var storyBody: String { l("Çekilişimize katıl, hediyeni kime alacağını Noel Baba söylesin!", "Join our draw and let Santa tell you who you're gifting!") }
    var storyCodeLabel: String { l("DAVET KODU", "INVITE CODE") }
    var storyHow: String { l("letsraffle.co'da ya da uygulamada kodu gir", "Enter the code at letsraffle.co or in the app") }
    var storyLinkCopied: String { l("Davet linki de kopyalandı; hikâyene bağlantı olarak ekleyebilirsin.", "The invite link was copied too; add it to your story as a link.") }
    var shareInstagramCopied: String { l("Davet metni kopyalandı; Instagram'da istediğin sohbete ya da hikâyeye yapıştırabilirsin.", "Invite text copied; paste it into any Instagram chat or story.") }
    var shareInstagramMissing: String { l("Instagram açılamadı. Davet metni kopyalandı, istediğin yere yapıştırabilirsin.", "Could not open Instagram. The invite text was copied so you can paste it anywhere.") }

    var emailChip: String { l("E-posta", "E-mail") }
    var guestChip: String { l("Hesapsız", "No account") }
    var newDrawTitle: String { l("Yeni bir çekiliş başlat", "Start a new draw") }
    var favTag: String { l("EN SEVİLEN", "MOST LOVED") }
    var inviteHeroTitle: String { l("Davet linkiyle", "With an invite link") }
    var inviteHeroDesc: String { l("Linki paylaş, herkes kendi bilgisini girsin.", "Share the link, everyone fills in their own details.") }
    var inviteHeroFeatures: String { l("Tarihli çekiliş · E-posta · Bildirim", "Scheduled draw · E-mail · Notifications") }
    var manualHeroTitle: String { l("İsimleri ben yazarım", "I'll enter the names") }
    var manualHeroDesc: String { l("Katılımcıları ekle, sonucu hemen gör.", "Add participants, see the result right away.") }
    var inviteCardTitle: String { l("Davet et", "Invite") }

    var codeNotFound: String { l("Bu kodla bir çekiliş bulamadık. Kodu kontrol edip tekrar dener misin?", "We couldn't find a draw with this code. Check it and try again?") }
    var codeNotFoundBubble: String { l("Listemde yok!", "Not on my list!") }

    // Home
    var hello: String { l("Merhaba", "Hello") }
    var myDraws: String { l("Çekilişlerim", "My draws") }
    var nextDraw: String { l("Sıradaki çekiliş", "Next draw") }
    var allEvents: String { l("Tüm etkinlikler", "All events") }
    var settingsHint: String { l("Hepsi isteğe bağlı.", "All optional.") }
    var manualSub: String { l("İsimleri ekle, çekilişi hemen yap.", "Add the names and draw right away.") }
    var optionalSection: String { l("İSTEĞE BAĞLI", "OPTIONAL") }
    var optionalNote: String { l("Biliyorsan yaz, bilmiyorsan boş bırak.", "Fill these in if you know them, or leave them empty.") }
    var removeParticipant: String { l("Katılımcıyı sil", "Remove participant") }
    var emptyManual: String { l("Henüz kimse yok. İlk katılımcıyı ekle!", "Nobody yet. Add the first participant!") }
    var tabHome: String { l("Ana Sayfa", "Home") }
    var tabEvents: String { l("Etkinliklerim", "My events") }
    var codePlaceholder: String { l("miskin-penguen-53", "jolly-reindeer-742") }
    var eventsSub: String { l("Kurdukların ve katıldıkların tek yerde.", "Created and joined, in one place.") }
    var eventsCreated: String { l("Oluşturduklarım", "Created") }
    var eventsJoined: String { l("Katıldıklarım", "Joined") }
    var eventsEmptyCreated: String { l("Henüz çekiliş oluşturmadın.", "You haven't created a draw yet.") }
    var eventsEmptyJoined: String { l("Henüz bir çekilişe katılmadın.", "You haven't joined a draw yet.") }
    var eventsSeeResult: String { l("Sonucu gör", "See result") }
    var eventsOpen: String { l("Aç", "Open") }
    var profileButton: String { l("Profil", "Profile") }
    var askSection: String { l("KATILIMCILARDAN İSTE", "ASK PARTICIPANTS FOR") }
    var whenSection: String { l("ÇEKİLİŞ ZAMANI", "WHEN TO DRAW") }
    var optAddressInfo: String { l("Herkes katılırken adresini yazar; hediyeler doğru adrese gider.", "Everyone enters their address when joining, so gifts reach the right door.") }
    var optPhoneInfo: String { l("Herkes katılırken telefonunu yazar; kargo ve iletişim kolaylaşır.", "Everyone enters their phone number when joining; handy for delivery.") }
    var optDateInfo: String { l("O saat gelince çekiliş kendiliğinden yapılır.", "The draw runs by itself at that time.") }
    var optDateOff: String { l("Kapalıyken çekilişi istediğin zaman sen başlatırsın.", "While off, you start the draw yourself whenever you like.") }
    var optAddress: String { l("Adres iste", "Ask for address") }
    var optPhone: String { l("Telefon iste", "Ask for phone") }
    var optDate: String { l("Tarih belirle", "Set a date") }
    var autoDrawOn: String { l("Otomatik çekiliş: %@", "Automatic draw: %@") }
    var newYearEyebrow: String { l("YILBAŞINA KALAN", "UNTIL NEW YEAR") }
    var unitDays: String { l("gün", "days") }
    var unitHours: String { l("saat", "hours") }
    var unitMinutes: String { l("dakika", "min") }
    var waitingTitle: String { l("Çekiliş henüz yapılmadı", "The draw hasn't run yet") }
    var waitingSub: String { l("Sonuç açıklanınca eşleşmeni burada göreceksin.", "You'll see your match here once it's out.") }
    var waitingBubble: String { l("Hâlâ mı çekilmedi?", "Is it time yet?") }
    var emailAlreadyJoined: String { l("Bu e-posta bu çekilişe zaten kayıtlı.", "This email is already registered for this draw.") }
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
    var backLabel: String { l("Geri", "Back") }
}
