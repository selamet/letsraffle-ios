import EventKit
import EventKitUI
import SwiftUI

/// The reveal, staged like the website: "Mutlu Yıllar" → Santa draws a name →
/// a shaking gift to tap open → who you're gifting (with address / phone).
struct RevealView: View {
    private enum Stage: Int { case hello, santa, gift, result }

    @State private var store: RevealStore
    @State private var stage: Stage = .hello
    @State private var santaReady = false
    @State private var opening = false
    @State private var confetti = 0
    @State private var copied: String?
    @State private var showReminder = false
    @State private var screenshotTaken = false
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(inviteCode: String, api: APIClient, participations: ParticipationStore, isSignedIn: Bool) {
        _store = State(initialValue: RevealStore(inviteCode: inviteCode, api: api, participations: participations, isSignedIn: isSignedIn))
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                if store.phase == .waiting {
                    // Sits right under the close ornament; only the brand at the bottom.
                    waiting
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                    Spacer(minLength: 0)
                    brandFooter
                        .padding(.bottom, 18)
                } else {
                    Spacer(minLength: 0)
                    content
                        .padding(.horizontal, 24)
                    Spacer(minLength: 0)
                    FriendsRow()
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
            }
            ConfettiBurst(trigger: confetti).ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
        .task {
            await store.load(t)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "revealOpen") { stage = .result }
            if UserDefaults.standard.string(forKey: "revealStage") != nil, let debugStage = Stage(rawValue: UserDefaults.standard.integer(forKey: "revealStage")) { stage = debugStage }
            #endif
        }
        .task(id: stage) {
            guard stage == .santa else { return }
            santaReady = false
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 3.4))
            if !Task.isCancelled { withAnimation(.easeOut(duration: 0.4)) { santaReady = true } }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            if stage == .result { screenshotTaken = true }
        }
        .sheet(isPresented: $showReminder) {
            if case let .revealed(result) = store.phase {
                ReminderEditor(title: "🎁 \(result.receiver.fullName)", notes: t.revealTitle, date: reminderDate)
                    .ignoresSafeArea()
            }
        }
    }

    private var reminderDate: Date {
        let base = store.drawDate.map { max($0, .now) } ?? .now
        return Calendar.current.date(byAdding: .day, value: 1, to: base) ?? base
    }

    private var background: some View {
        ZStack {
            // No mountains behind the waiting text.
            ChristmasBackdrop(garland: true, pines: store.phase != .waiting)
            RadialGradient(colors: [Palette.goldLight.opacity(0.22), .clear], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 240)
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(alignment: .bottom) {
            OrnamentBackButton(stringLength: 62, systemName: "xmark") { dismiss() }
            Spacer()
            // While waiting, the name is the headline of the page instead.
            if store.phase != .waiting {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(drawName).font(AppFont.script(26))
                    if let number = drawNumber { Text("No. \(number)").font(AppFont.body(11, .black)).tracking(1) }
                }
                .foregroundStyle(Palette.goldLight)
                .lineLimit(1)
                .padding(.bottom, 6)
            }
            Spacer()
            Color.clear.frame(width: 48, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
    }

    private func go(_ next: Stage) {
        if next == .gift { opening = false }
        withAnimation(.easeInOut(duration: 0.35)) { stage = next }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ChristmasLoader(label: t.revealLoading, onDark: true, width: 150)
        case .waiting:
            waiting
        case let .failed(message):
            VStack(spacing: 14) {
                FriendImage(friend: .rudolph, width: 96)
                infoText(message)
                Button(t.retry) { Task { await store.load(t) } }.foregroundStyle(Palette.goldLight).font(AppFont.body(15, .bold))
            }
        case let .revealed(result):
            Group {
                switch stage {
                case .hello: hello
                case .santa: santa
                case .gift: gift
                case .result: resultView(result)
                }
            }
            .id(stage)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 14)),
                removal: .opacity.combined(with: .offset(y: -10))
            ))
        }
    }

    /// "miskin-penguen-768" → "Miskin Penguen".
    private var drawName: String {
        let words = store.inviteCode.split(separator: "-").filter { Int($0) == nil }
        guard !words.isEmpty else { return store.inviteCode }
        return words.map { $0.capitalized }.joined(separator: " ")
    }

    /// The number at the end of the invite code ("768"), if it has one.
    private var drawNumber: String? {
        store.inviteCode.split(separator: "-").last.flatMap { Int($0) == nil ? nil : String($0) }
    }

    /// Draw not run yet: the draw's name, Santa checking his watch, and the brand.
    private var waiting: some View {
        VStack(spacing: 8) {
            Text(drawName)
                .font(AppFont.script(54))
                .foregroundStyle(Palette.goldLight)
                .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 3)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let number = drawNumber {
                Text("No. \(number)")
                    .font(AppFont.body(12, .black)).tracking(1.4)
                    .foregroundStyle(Palette.goldText)
                    .padding(.horizontal, 12)
                    .frame(height: 24)
                    .background(Palette.goldGradient, in: Capsule())
                    .padding(.top, -6)
                    .padding(.bottom, 4)
            }
            Text(t.waitingTitle)
                .font(AppFont.display(22))
                .foregroundStyle(Palette.snow)
                .multilineTextAlignment(.center)
            // Speech bubble right above his head, its tail pointing down at him.
            Text(t.waitingBubble)
                .font(AppFont.display(16))
                .foregroundStyle(Palette.brandText)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(SpeechBubble().fill(Palette.snow))
                .overlay(SpeechBubble().stroke(Palette.gold, lineWidth: 2))
                .shadow(color: Color(hex: 0x3C0000, alpha: 0.25), radius: 6, y: 4)
                .fixedSize()
                .padding(.top, 14)
            SantaAvatar(size: 160, mood: .watch)
                .padding(.top, -22)
            if let date = store.drawDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 12, weight: .bold))
                    Text(DrawDateFormat.long(date, language: settings.language))
                }
                .font(AppFont.body(13, .black))
                .foregroundStyle(Palette.snow)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(Color.white.opacity(0.16), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
            }
            infoText(t.waitingSub)
                .padding(.top, 4)
        }
    }

    private var brandFooter: some View {
        VStack(spacing: 0) {
            Image("lockup")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .accessibilityLabel("Lets Raffle")
            Text("letsraffle.co")
                .font(AppFont.body(14, .bold))
                .foregroundStyle(Palette.snow.opacity(0.9))
        }
    }

    // MARK: Stages

    private var hello: some View {
        VStack(spacing: 8) {
            Text(t.revealEyebrow)
                .font(AppFont.body(12, .black)).tracking(2.6)
                .foregroundStyle(Palette.goldLight)
            Text(t.happyNewYear)
                .font(AppFont.script(60))
                .foregroundStyle(Palette.goldLight)
                .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 3)
                .minimumScaleFactor(0.7).lineLimit(1)
            if let name = store.firstName {
                Text("\(name)!").font(AppFont.display(28)).foregroundStyle(Palette.snow)
            }
            SantaAvatar(size: 170, mood: .wave)
            Text(t.revealHelloText)
                .font(AppFont.body(16, .semibold))
                .foregroundStyle(Palette.snow.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button { go(.santa) } label: {
                HStack(spacing: 8) { Text(t.revealShow); Image(systemName: "arrow.right") }
            }
            .buttonStyle(.gold)
            .frame(maxWidth: 260)
            .padding(.top, 8)
            .accessibilityIdentifier("reveal.start")
            dots(0)
        }
    }

    private var santa: some View {
        VStack(spacing: 10) {
            Text(t.revealSantaTitle)
                .font(AppFont.display(28))
                .foregroundStyle(Palette.snow)
                .multilineTextAlignment(.center)
            SantaAvatar(size: 200, mood: .draw)
            Text(santaReady ? t.revealSantaFound : t.revealSantaSearching)
                .font(AppFont.body(16, .semibold))
                .foregroundStyle(Palette.snow.opacity(0.92))
                .multilineTextAlignment(.center)
            Button { go(.gift) } label: { Text(t.revealBringGift) }
                .buttonStyle(.gold)
                .frame(maxWidth: 240)
                .padding(.top, 6)
                .opacity(santaReady ? 1 : 0)
                .disabled(!santaReady)
            dots(1)
        }
    }

    private var gift: some View {
        VStack(spacing: 8) {
            Text(t.revealGiftTitle)
                .font(AppFont.display(30))
                .foregroundStyle(Palette.snow)
            Text(opening ? t.revealGiftOpening : t.revealGiftText)
                .font(AppFont.body(16, .semibold))
                .foregroundStyle(Palette.snow.opacity(0.92))
                .multilineTextAlignment(.center)
            Button(action: openGift) {
                GiftVideo(opening: opening)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.plain)
            .disabled(opening)
            .sensoryFeedback(.success, trigger: opening)
            .accessibilityLabel(t.revealGiftCta)
            .accessibilityIdentifier("reveal.gift")
            Text("\(t.revealGiftCta) 👆")
                .font(AppFont.body(13, .black)).tracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(Palette.goldLight)
                .opacity(opening ? 0 : 1)
                .padding(.top, 10)
            dots(2)
        }
    }

    private func openGift() {
        guard !opening else { return }
        opening = true
        let burstDelay = reduceMotion ? 0.0 : 0.65
        let revealDelay = reduceMotion ? 0.25 : 1.9
        DispatchQueue.main.asyncAfter(deadline: .now() + burstDelay) { confetti += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) { stage = .result }
        }
    }

    private func resultView(_ result: MatchResult) -> some View {
        VStack(spacing: 0) {
            Image("gift-opened")
                .resizable().scaledToFit()
                .frame(width: 130)
                .padding(.bottom, -22)
                .accessibilityHidden(true)
            receiverCard(result.receiver)
            infoText(screenshotTaken ? t.screenshotWarning : t.revealSecret)
                .padding(.top, 12)
            HStack(spacing: 18) {
                Button { showReminder = true } label: {
                    Label(t.addReminder, systemImage: "calendar.badge.plus")
                }
                Button { go(.hello) } label: {
                    Label(t.revealReplay, systemImage: "arrow.counterclockwise")
                }
            }
            .font(AppFont.body(14, .bold))
            .foregroundStyle(Palette.goldLight)
            .frame(minHeight: 44)
            .padding(.top, 4)
        }
    }

    private func receiverCard(_ receiver: MatchResult.Receiver) -> some View {
        VStack(spacing: 10) {
            Text(t.revealResultEyebrow)
                .font(AppFont.body(11, .black)).tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Palette.brand)
            Text(receiver.fullName)
                .font(AppFont.display(34))
                .foregroundStyle(Palette.brandText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("reveal.receiver")
            CandyStripe(width: 96, height: 8)
            if let address = receiver.address, !address.isEmpty {
                detailRow(icon: "mappin.and.ellipse", text: address)
            }
            if let phone = receiver.phone, !phone.isEmpty {
                detailRow(icon: "phone.fill", text: phone)
            }
            Text(t.revealSecretNote)
                .font(AppFont.body(14, .bold))
                .foregroundStyle(Palette.greenText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Palette.greenSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .foilCard(radius: 28)
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.brand)
                .frame(width: 22)
            Text(text)
                .font(AppFont.body(15, .semibold))
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIPasteboard.general.string = text
                copied = text
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { if copied == text { copied = nil } }
            } label: {
                Text(copied == text ? t.copied : t.copy)
                    .font(AppFont.body(12, .black))
                    .foregroundStyle(Palette.brandText)
                    .padding(.horizontal, 12).frame(minHeight: 32)
                    .background(Palette.amberSoft, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
    }

    private func dots(_ active: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == active ? Palette.goldLight : Palette.snow.opacity(0.4))
                    .frame(width: i == active ? 24 : 8, height: 8)
            }
        }
        .padding(.top, 14)
        .accessibilityHidden(true)
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.body(14, .bold))
            .foregroundStyle(Palette.snow.opacity(0.85))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 300)
    }
}

/// Rounded speech bubble with a small tail at the bottom centre (the tail is 10pt tall).
private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let tail: CGFloat = 10
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tail)
        let r = min(18, body.height / 2)
        let mid = rect.midX
        var p = Path()
        p.move(to: CGPoint(x: body.minX + r, y: body.minY))
        p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
        p.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.minY + r), radius: r)
        p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
        p.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY), tangent2End: CGPoint(x: body.maxX - r, y: body.maxY), radius: r)
        p.addLine(to: CGPoint(x: mid + 9, y: body.maxY))
        p.addLine(to: CGPoint(x: mid, y: rect.maxY))
        p.addLine(to: CGPoint(x: mid - 9, y: body.maxY))
        p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
        p.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.maxY - r), radius: r)
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
        p.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY), tangent2End: CGPoint(x: body.minX + r, y: body.minY), radius: r)
        p.closeSubpath()
        return p
    }
}

/// The Blender gift box: shakes on a loop, then plays the opening clip once.
private struct GiftVideo: View {
    let opening: Bool
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.goldLight.opacity(0.55), Palette.goldLight.opacity(0)], center: .center, startRadius: 0, endRadius: 120))
                .padding(18)
            if reduceMotion {
                Image(opening ? "gift-opened" : "gift-closed").resizable().scaledToFit()
            } else {
                AlphaVideo(name: "gift-shake", loops: true, isPlaying: !opening)
                    .opacity(opening ? 0 : 1)
                AlphaVideo(name: "gift-open", loops: false, isPlaying: opening)
                    .opacity(opening ? 1 : 0)
            }
        }
        .aspectRatio(440.0 / 386.0, contentMode: .fit)
        .scaleEffect(pulse && !opening ? 1.04 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

/// System event editor (no calendar permission needed to present it).
struct ReminderEditor: UIViewControllerRepresentable {
    let title: String
    let notes: String
    let date: Date
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.isAllDay = true
        event.startDate = date
        event.endDate = date
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}
