import EventKit
import EventKitUI
import SwiftUI

/// "Who are you gifting this year?" — tap the gift to reveal the match.
struct RevealView: View {
    @State private var store: RevealStore
    @State private var opened = false
    @State private var showReminder = false
    @State private var screenshotTaken = false
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss

    init(inviteCode: String, api: APIClient, participations: ParticipationStore, isSignedIn: Bool) {
        _store = State(initialValue: RevealStore(inviteCode: inviteCode, api: api, participations: participations, isSignedIn: isSignedIn))
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                content
                    .padding(.horizontal, 24)
                Spacer(minLength: 0)
                actions
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.load(t)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "revealOpen") { opened = true }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            if opened { screenshotTaken = true }
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
            ChristmasBackdrop(garland: true, pines: true)
            RadialGradient(colors: [Palette.goldLight.opacity(0.3), .clear], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 240)
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(onDark: true) { dismiss() }
            Spacer()
            Text(store.inviteCode).font(AppFont.body(13, .black)).tracking(1.2).foregroundStyle(Palette.goldLight)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            Text(t.yourMatch)
                .font(AppFont.script(40))
                .foregroundStyle(Palette.goldLight)
            Text(t.revealTitle)
                .font(AppFont.display(28))
                .foregroundStyle(Palette.snow)
                .multilineTextAlignment(.center)

            switch store.phase {
            case .loading:
                GiftBox(opened: false).opacity(0.6)
                ProgressView().tint(.white)
            case .waiting:
                GiftBox(opened: false)
                infoText(t.waitingForDraw)
            case let .failed(message):
                GiftBox(opened: false).opacity(0.6)
                infoText(message)
                Button(t.retry) { Task { await store.load(t) } }.foregroundStyle(Palette.goldLight).font(AppFont.body(15, .bold))
            case let .revealed(result):
                Button {
                    withAnimation(.spring(duration: 0.6, bounce: 0.35)) { opened = true }
                } label: {
                    GiftBox(opened: opened)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: opened)
                .accessibilityLabel(t.tapToReveal)
                .accessibilityIdentifier("reveal.gift")

                if opened {
                    receiverCard(result.receiver)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    infoText(screenshotTaken ? t.screenshotWarning : t.revealSecret)
                } else {
                    infoText(t.tapToReveal)
                }
            }
        }
    }

    private func receiverCard(_ receiver: MatchResult.Receiver) -> some View {
        HStack(spacing: 14) {
            Text(Participant.initials(receiver.firstName, receiver.lastName))
                .font(AppFont.display(19))
                .foregroundStyle(Palette.cranberryDark)
                .frame(width: 54, height: 54)
                .background(Palette.goldGradient, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(receiver.fullName).font(AppFont.display(22)).foregroundStyle(Palette.brandText)
                let details = [receiver.address.map { "📍 \($0)" }, receiver.phone.map { "📞 \($0)" }].compactMap { $0 }
                if !details.isEmpty {
                    Text(details.joined(separator: " · ")).font(AppFont.body(13, .semibold)).foregroundStyle(Palette.sub)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .foilCard(radius: 24)
        .accessibilityIdentifier("reveal.receiver")
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.body(14, .bold))
            .foregroundStyle(Palette.snow.opacity(0.85))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if opened {
                Button { showReminder = true } label: {
                    Label(t.addReminder, systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.gold)
            }
            Button(t.done) { dismiss() }
                .font(AppFont.body(15, .bold))
                .foregroundStyle(Palette.snow.opacity(0.9))
                .frame(height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

/// Drawn gift box; the lid lifts and tilts when opened.
struct GiftBox: View {
    var opened: Bool

    var body: some View {
        ZStack {
            Circle().fill(Palette.goldLight.opacity(0.22)).blur(radius: 30)
            ZStack(alignment: .top) {
                // Box
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x2F7A55), Palette.pine], startPoint: .top, endPoint: .bottom))
                    .frame(width: 160, height: 130)
                    .overlay(Rectangle().fill(Palette.gold).frame(width: 22))
                    .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
                    .offset(y: 90 - 44)
                // Lid + bow
                ZStack(alignment: .top) {
                    Bow().stroke(Palette.gold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 70, height: 40)
                        .offset(y: -30)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0x3A8A62), Color(hex: 0x2F7A55)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 176, height: 48)
                        .overlay(Rectangle().fill(Palette.gold).frame(width: 22))
                        .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
                }
                .rotationEffect(.degrees(opened ? -18 : 0), anchor: .bottomLeading)
                .offset(x: opened ? -20 : 0, y: opened ? -70 : 0)
                .opacity(opened ? 0 : 1)
            }
            .frame(width: 176, height: 180)
            .scaleEffect(opened ? 0.7 : 1)
        }
        .frame(width: 220, height: 220)
    }
}

private struct Bow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.minX, y: rect.minY - rect.height * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY - rect.height * 0.4))
        return p
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
