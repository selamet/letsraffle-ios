import SwiftUI

/// "Manage Your Draw" — the organizer adds everyone and runs the draw at once.
struct ManualDrawView: View {
    var onFinish: () -> Void

    @State private var model = ManualDrawView.makeModel()
    @State private var editing: ParticipantInput?
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Group {
            if model.completedDrawId != nil {
                ManualSuccessView(onDone: onFinish)
            } else {
                editor
            }
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
        #if DEBUG
        .task {
            if UserDefaults.standard.bool(forKey: "manualSheet") { addParticipant() }
        }
        #endif
        .sheet(item: $editing) { participant in
            ParticipantSheet(model: model, participant: participant)
        }
    }

    private static func makeModel() -> ManualDrawModel {
        let model = ManualDrawModel()
        #if DEBUG
        // Visual QA: `-manualDemo YES`
        if UserDefaults.standard.bool(forKey: "manualDemo") {
            model.upsert(ParticipantInput(firstName: "Ayşe", lastName: "Demir", email: "ayse@example.com", address: "Kadıköy / İstanbul"))
            model.upsert(ParticipantInput(firstName: "Mert", lastName: "Kaya", email: "mert@example.com"))
        }
        #endif
        return model
    }

    private func addParticipant() {
        editing = ParticipantInput(firstName: "", lastName: "", email: "")
    }

    /// Same frame as the invite steps: the red scene stays put, the list scrolls in the cream
    /// sheet and the draw button is pinned to the bottom.
    private var editor: some View {
        StepScaffold(title: t.manageTitle, subtitle: t.manualSub, mood: .draw) {
            Button(action: addParticipant) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Palette.pine)
                        .frame(width: 34, height: 34)
                        .background(Palette.goldGradient, in: Circle())
                    Text(t.addParticipant)
                        .font(AppFont.display(19))
                        .foregroundStyle(Palette.goldLight)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(
                    LinearGradient(colors: [Color(hex: 0x2F8A5A), Palette.pine, Palette.pineEdge], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.goldLight, lineWidth: 2.5))
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: 0x0C2A1C)).offset(y: 5))
                .padding(.bottom, 5)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manual.add")

            HStack(alignment: .firstTextBaseline) {
                Text(t.treeTitle)
                    .font(AppFont.display(19))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text(t.participantCount(model.participants.count))
                    .font(AppFont.body(13, .black))
                    .foregroundStyle(Palette.brandText)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Palette.chip, in: Capsule())
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)

            if model.participants.isEmpty {
                EmptyHint(text: t.emptyManual)
            } else {
                VStack(spacing: 10) {
                    ForEach(model.participants) { p in
                        Button { editing = p } label: { row(p) }
                            .buttonStyle(.plain)
                    }
                }
                .animation(.spring(duration: 0.3), value: model.participants)
            }
        } bottom: {
            bottomBar
        }
    }

    private func row(_ p: ParticipantInput) -> some View {
        HStack(spacing: 12) {
            Avatar(initials: Participant.initials(p.firstName, p.lastName))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.fullName).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text).lineLimit(1)
                Text([p.email, p.address].compactMap { $0 }.joined(separator: " · "))
                    .font(AppFont.body(13, .medium))
                    .foregroundStyle(Palette.sub)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.brandText)
                .frame(width: 32, height: 32)
                .background(Palette.chip, in: Circle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
        .contentShape(Rectangle())
    }

    private var bottomBar: some View {
        let count = model.participants.count
        let minimum = ManualDrawModel.minimumParticipants
        return VStack(spacing: 8) {
            if let error = model.submitError {
                Banner(text: error, style: .error)
            }
            if count < minimum {
                // Three baubles fill up as people are added.
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        ForEach(0..<minimum, id: \.self) { index in
                            Circle()
                                .fill(index < count ? AnyShapeStyle(Palette.goldGradient) : AnyShapeStyle(Palette.cardBorder))
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text(t.minHint)
                        .font(AppFont.body(12.5, .bold))
                        .foregroundStyle(Palette.sub)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .animation(.spring(duration: 0.3), value: count)
            }
            Button(t.runDraw) {
                Task { await model.submit(api: session.api, language: settings.language, t) }
            }
            .buttonStyle(.festive(loading: model.isSubmitting))
            .disabled(!model.canRun)
            .accessibilityIdentifier("manual.run")
            Text(t.manualEmailNote)
                .font(AppFont.body(12, .bold))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
    }
}

/// Add / edit participant sheet with contact import. Only the name and e-mail are needed;
/// address and phone sit in their own "optional" group.
private struct ParticipantSheet: View {
    let model: ManualDrawModel
    @State var participant: ParticipantInput
    @State private var showErrors = false
    @State private var pickingContact = false
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss

    private var isNew: Bool { !model.participants.contains { $0.id == participant.id } }

    var body: some View {
        let errors = showErrors ? model.error(for: participant, editing: participant.id, t) : [:]
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Button { pickingContact = true } label: {
                        Label(t.importContacts, systemImage: "person.crop.circle.badge.plus")
                            .font(AppFont.body(14, .black))
                            .foregroundStyle(Palette.brandText)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(Palette.chip, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    HStack(alignment: .top, spacing: 12) {
                        FormField(label: t.firstName, text: $participant.firstName, placeholder: t.firstNamePh, kind: .name, isRequired: true, error: errors[.firstName])
                        FormField(label: t.lastName, text: $participant.lastName, placeholder: t.lastNamePh, kind: .name, isRequired: true, error: errors[.lastName])
                    }
                    FormField(label: t.email, text: $participant.email, placeholder: t.emailPh, kind: .email, isRequired: true, error: errors[.email])

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.optionalSection)
                                .font(AppFont.body(12, .black)).tracking(1.8)
                                .foregroundStyle(Palette.greenText)
                            Text(t.optionalNote)
                                .font(AppFont.body(13, .bold))
                                .foregroundStyle(Palette.sub)
                        }
                        FormField(label: t.address, text: optional(\.address), placeholder: t.addressPh, icon: "mappin.and.ellipse")
                        FormField(label: t.phone, text: optional(\.phone), placeholder: t.phonePh, kind: .phone)
                    }
                    .padding(14)
                    .background(Palette.greenSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Palette.greenText.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    )
                    .padding(.top, 4)

                    Button(isNew ? t.add : t.save, action: save)
                        .buttonStyle(.festive(loading: false))
                        .padding(.top, 4)

                    if !isNew {
                        Button(role: .destructive) {
                            model.remove(participant.id)
                            dismiss()
                        } label: {
                            Label(t.removeParticipant, systemImage: "trash")
                                .font(AppFont.body(15, .bold))
                                .foregroundStyle(Palette.brandText)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.page)
            .navigationTitle(t.addParticipant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t.cancel) { dismiss() } }
            }
            .background {
                ContactPicker(isPresented: $pickingContact) { contact in
                    participant.firstName = contact.firstName
                    participant.lastName = contact.lastName
                    participant.email = contact.email ?? participant.email
                    participant.phone = contact.phone ?? participant.phone
                    participant.address = contact.address ?? participant.address
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func optional(_ keyPath: WritableKeyPath<ParticipantInput, String?>) -> Binding<String> {
        Binding(
            get: { participant[keyPath: keyPath] ?? "" },
            set: { participant[keyPath: keyPath] = $0 }
        )
    }

    private func save() {
        showErrors = true
        guard model.error(for: participant, editing: participant.id, t).isEmpty else { return }
        model.upsert(participant)
        dismiss()
    }
}

/// Shown after a manual draw was submitted: Santa draws from his sack, then celebrates.
struct ManualSuccessView: View {
    var onDone: () -> Void
    @Environment(\.strings) private var t
    @State private var revealed = false

    var body: some View {
        ZStack {
            ChristmasBackdrop(garland: false, pines: false)
            VStack(spacing: 14) {
                Spacer(minLength: 20)
                if revealed {
                    Text(t.allReady).font(AppFont.script(46)).foregroundStyle(Palette.goldLight)
                        .transition(.scale.combined(with: .opacity))
                    Text(t.successTitle).font(AppFont.display(28)).foregroundStyle(Palette.snow)
                    Text(t.manualSuccess)
                        .font(AppFont.body(15, .semibold))
                        .foregroundStyle(Palette.snow.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                } else {
                    Text(t.santaDrawing).font(AppFont.display(26)).foregroundStyle(Palette.snow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                SantaAvatar(size: 290, mood: revealed ? .celebrate : .draw)
                    .id(revealed)
                    .transition(.opacity)
                if revealed {
                    Text("★ \(t.happyHolidays) ★").font(AppFont.body(15, .bold)).foregroundStyle(Palette.goldLight)
                } else {
                    Text(t.shuffling)
                        .font(AppFont.body(14, .bold))
                        .foregroundStyle(Palette.snow.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                Spacer(minLength: 10)
                Button(t.done, action: onDone)
                    .buttonStyle(.gold)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 14)
                    .opacity(revealed ? 1 : 0)
                    .disabled(!revealed)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4.5))
            withAnimation(.spring(duration: 0.6)) { revealed = true }
        }
        .sensoryFeedback(.success, trigger: revealed)
    }
}
