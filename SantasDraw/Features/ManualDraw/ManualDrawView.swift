import SwiftUI

/// "Manage Your Draw" — the organizer adds everyone and runs the draw at once.
struct ManualDrawView: View {
    var onFinish: () -> Void

    @State private var model = ManualDrawModel()
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
        .sheet(item: $editing) { participant in
            ParticipantSheet(model: model, participant: participant)
        }
    }

    private var editor: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton { dismiss() }
                Spacer()
                Button { editing = ParticipantInput(firstName: "", lastName: "", email: "") } label: {
                    Label(t.addParticipant, systemImage: "plus")
                        .font(AppFont.body(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(Palette.pine, in: Capsule())
                        .background(Palette.pineEdge, in: Capsule().offset(y: 3))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("manual.add")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            List {
                Group {
                    ScreenHeader(eyebrow: t.manualMode, title: t.manageTitle, titleSize: 30)
                        .padding(.horizontal, 8)
                    summary
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                Section {
                    if model.participants.isEmpty {
                        Button { editing = ParticipantInput(firstName: "", lastName: "", email: "") } label: {
                            Label(t.addParticipant, systemImage: "person.badge.plus")
                                .foregroundStyle(Palette.brandText)
                        }
                    }
                    ForEach(model.participants) { p in
                        Button { editing = p } label: { row(p) }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(t.delete, role: .destructive) { model.remove(p.id) }
                            }
                    }
                    .listRowBackground(Palette.card)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 52 }
                } header: {
                    Text(t.treeTitle)
                        .font(AppFont.display(19))
                        .foregroundStyle(Palette.text)
                        .textCase(nil)
                        .padding(.horizontal, -16)
                } footer: {
                    if model.participants.count > 1 {
                        Text("← \(t.swipeHint)").font(AppFont.body(12, .semibold)).foregroundStyle(Palette.ter).frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 4, for: .scrollContent)
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(model.participants.count)")
                    .font(AppFont.display(30))
                    .foregroundStyle(Palette.brandText)
                    .contentTransition(.numericText())
                Text(t.participants).font(AppFont.body(13, .bold)).foregroundStyle(Palette.sub)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.card2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.gold.opacity(0.6), lineWidth: 2))

            VStack(alignment: .leading, spacing: 6) {
                CheckRow(title: t.addressReq, isOn: $model.requireAddress)
                CheckRow(title: t.phoneReq, isOn: $model.requirePhone)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.default, value: model.participants.count)
    }

    private func row(_ p: ParticipantInput) -> some View {
        HStack(spacing: 12) {
            Avatar(initials: Participant.initials(p.firstName, p.lastName))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.fullName).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
                Text([p.email, p.address].compactMap { $0 }.joined(separator: " · "))
                    .font(AppFont.body(13, .medium))
                    .foregroundStyle(Palette.sub)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if model.isIncomplete(p) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Palette.amber)
            } else {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var bottomBar: some View {
        let count = model.participants.count
        let minimum = ManualDrawModel.minimumParticipants
        return VStack(spacing: 8) {
            if let error = model.submitError {
                Banner(text: error, style: .error)
            }
            HStack {
                Text(t.participantCount(count))
                Spacer()
                Text(count >= minimum ? t.readyForDraw : t.minHint)
                    .foregroundStyle(count >= minimum ? Palette.greenText : Palette.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(AppFont.body(13, .bold))
            .foregroundStyle(Palette.sub)
            GeometryReader { geo in
                Capsule().fill(Color(light: 0xF1E3D3, dark: 0x3A2224))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LinearGradient(colors: [Palette.brand, Color(hex: 0xE8474C)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * min(1, CGFloat(count) / CGFloat(max(minimum, 1))))
                    }
            }
            .frame(height: 10)
            .animation(.spring(duration: 0.4), value: count)
            Button(t.runDraw) {
                Task { await model.submit(api: session.api, language: settings.language, t) }
            }
            .buttonStyle(.primary(loading: model.isSubmitting))
            .disabled(!model.canRun)
            .accessibilityIdentifier("manual.run")
            Text(t.manualEmailNote)
                .font(AppFont.body(12, .bold))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            Palette.card
                .shadow(color: Color(hex: 0x6E0D12, alpha: 0.08), radius: 15, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Small checkbox row used in the manual draw summary card.
private struct CheckRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isOn ? Palette.brand : .clear)
                    .strokeBorder(isOn ? Palette.brand : Palette.fieldBorder, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                    .overlay {
                        if isOn { Image(systemName: "checkmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white) }
                    }
                Text(title).font(AppFont.body(13, .bold)).foregroundStyle(isOn ? Palette.text : Palette.sub)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Add / edit participant sheet with contact import.
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
                VStack(spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        FormField(label: t.firstName, text: $participant.firstName, placeholder: t.firstNamePh, kind: .name, error: errors[.firstName])
                        FormField(label: t.lastName, text: $participant.lastName, placeholder: t.lastNamePh, kind: .name, error: errors[.lastName])
                    }
                    FormField(label: t.email, text: $participant.email, placeholder: t.emailPh, kind: .email, isRequired: true, error: errors[.email])
                    FormField(label: t.address, text: optional(\.address), placeholder: t.addressPh, isRequired: model.requireAddress, error: errors[.address])
                    FormField(label: t.phone, text: optional(\.phone), placeholder: t.phonePh, kind: .phone, isRequired: model.requirePhone, error: errors[.phone])

                    Button { pickingContact = true } label: {
                        Label(t.importContacts, systemImage: "person.crop.circle.badge.plus")
                            .font(AppFont.body(15, .bold))
                            .foregroundStyle(Palette.brandText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(20)
            }
            .background(Palette.page)
            .navigationTitle(t.addParticipant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? t.add : t.save, action: save).fontWeight(.semibold)
                }
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
