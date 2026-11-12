import SwiftUI

/// Common layout for the two "create a draw" steps: the red winter scene stays put at the
/// top (hanging back ornament, title in script, step pills, Santa); the cream sheet below
/// scrolls and keeps its action pinned to the bottom.
struct StepScaffold<Content: View, Bottom: View>: View {
    var step: String?
    /// 1-based position of this step (out of two), drawn as gold pills.
    var stepIndex: Int = 1
    let title: String
    var subtitle: String?
    var mood: SantaMood = .list
    @ViewBuilder var content: Content
    @ViewBuilder var bottom: Bottom

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)

                bottom
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                    .fill(Palette.page)
                    .shadow(color: Color(hex: 0x320000, alpha: 0.3), radius: 18, y: -8)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(alignment: .top) {
            ChristmasBackdrop(garland: true, pines: false).frame(height: 420)
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // The string runs up behind the status bar, as if hanging from the top edge.
                OrnamentBackButton(stringLength: 50) { dismiss() }
                Spacer()
            }
            .padding(.leading, 12)
            .padding(.top, -46)
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppFont.script(40))
                        .foregroundStyle(Palette.goldLight)
                        .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.4), radius: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.body(14, .bold))
                            .foregroundStyle(Palette.snow.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let step {
                        HStack(spacing: 6) {
                            ForEach(1...2, id: \.self) { index in
                                Capsule()
                                    .fill(index <= stepIndex ? AnyShapeStyle(Palette.goldGradient) : AnyShapeStyle(Color.white.opacity(0.28)))
                                    .frame(width: 30, height: 6)
                            }
                            Text(step)
                                .font(AppFont.body(11, .black)).tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundStyle(Palette.snow.opacity(0.9))
                                .padding(.leading, 4)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 18)
                Spacer(minLength: 0)
                SantaAvatar(size: 100, mood: mood)
            }
            .padding(.leading, 22)
            .padding(.trailing, 6)
            .padding(.top, 2)
        }
    }
}

/// Step 1/2 — what to ask the participants for, and when to draw. Three switches, one line
/// each; the date opens its pickers inside its own card.
struct InviteSettingsView: View {
    @Binding var path: [DrawsRoute]
    @Bindable var draft: InviteDraft
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings

    private var hour: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: draft.drawDate) },
            set: { draft.drawDate = Calendar.current.date(bySettingHour: $0, minute: 0, second: 0, of: draft.drawDate) ?? draft.drawDate }
        )
    }

    private var day: Binding<Date> {
        Binding(
            get: { draft.drawDate },
            set: { newDay in
                let h = Calendar.current.component(.hour, from: draft.drawDate)
                draft.drawDate = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: newDay) ?? newDay
            }
        )
    }

    var body: some View {
        StepScaffold(step: t.step1of2, stepIndex: 1, title: t.settingsTitle, subtitle: t.settingsHint) {
            sectionTitle(t.askSection)
            option(icon: "mappin.and.ellipse", tone: 0, title: t.optAddress, isOn: $draft.requireAddress, info: t.optAddressInfo)
            option(icon: "phone.fill", tone: 1, title: t.optPhone, isOn: $draft.requirePhone, info: t.optPhoneInfo)

            sectionTitle(t.whenSection).padding(.top, 6)
            option(icon: "calendar", tone: 2, title: t.optDate, isOn: $draft.scheduleEnabled, info: nil, offInfo: t.optDateOff) {
                schedule
            }
        } bottom: {
            Button {
                path.append(.inviteDetails)
            } label: {
                HStack(spacing: 8) {
                    Text(t.continueTitle)
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.festive(loading: false))
            .accessibilityIdentifier("invite.continue")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppFont.body(12, .black)).tracking(1.8)
            .foregroundStyle(Palette.sub)
            .padding(.horizontal, 8)
            .padding(.bottom, -4)
    }

    /// Two labelled fields (date, hour) and a summary of what will happen.
    private var schedule: some View {
        let past = draft.drawDate <= .now
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                pickerField(label: t.dateLabel, icon: "calendar") {
                    DatePicker("", selection: day, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                        .labelsHidden()
                        .tint(Palette.brand)
                        .accessibilityLabel(t.dateLabel)
                }
                pickerField(label: t.timeLabel, icon: "clock.fill") {
                    Picker("", selection: hour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .tint(Palette.brandText)
                    .accessibilityLabel(t.timeLabel)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: past ? "exclamationmark.triangle.fill" : "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(past ? t.pastDate : DrawDateFormat.long(draft.drawDate, language: settings.language))
                        .font(AppFont.display(16))
                        .fixedSize(horizontal: false, vertical: true)
                    if !past {
                        Text(t.optDateInfo)
                            .font(AppFont.body(12.5, .bold))
                            .opacity(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(past ? Palette.brandText : Palette.greenText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(past ? Palette.chip : Palette.greenSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private func pickerField<Control: View>(label: String, icon: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(label).font(AppFont.body(11, .black)).tracking(1.2).textCase(.uppercase)
            }
            .foregroundStyle(Palette.sub)
            control()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.fieldBorder, lineWidth: 2))
    }

    private func option(icon: String, tone: Int, title: String, isOn: Binding<Bool>, info: String?) -> some View {
        option(icon: icon, tone: tone, title: title, isOn: isOn, info: info, offInfo: nil) { EmptyView() }
    }

    /// One switch per card: bauble icon, a short title, the candy toggle. Tapping anywhere on
    /// the row flips it. While it is on, `extra` and a short note (`info`) open inside the
    /// card; `offInfo` is the note for the off state, when that needs saying.
    private func option<Extra: View>(icon: String, tone: Int, title: String, isOn: Binding<Bool>, info: String?, offInfo: String?, @ViewBuilder extra: () -> Extra) -> some View {
        let palettes: [([Color], Color, Color)] = [
            ([Color(hex: 0xE0444A), Palette.cranberry, Palette.cranberryDark], Color(hex: 0x4A080C), Palette.snow),
            ([Color(hex: 0x3F9A63), Palette.pine, Palette.pineEdge], Color(hex: 0x0C2A1C), Palette.snow),
            ([Color(hex: 0xFDF0C4), Palette.gold, Palette.goldDark], Color(hex: 0x8A6A1E), Palette.goldText),
        ]
        let (colors, edge, foreground) = palettes[tone % palettes.count]
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let on = isOn.wrappedValue
        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(RadialGradient(colors: colors, center: UnitPoint(x: 0.34, y: 0.28), startRadius: 1, endRadius: 30)))
                    .overlay(Circle().strokeBorder(Palette.goldLight.opacity(0.85), lineWidth: 2))
                    .background(Circle().fill(edge).offset(y: 3))
                    .saturation(on ? 1 : 0.55)
                Text(title)
                    .font(AppFont.display(19))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                Toggle(isOn: isOn.animation(.spring(duration: 0.3))) { EmptyView() }
                    .toggleStyle(CandyToggleStyle())
                    .accessibilityLabel(title)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 70)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.spring(duration: 0.3)) { isOn.wrappedValue.toggle() } }

            if on {
                extra().transition(.opacity)
            }
            if let note = on ? info : offInfo {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: on ? "checkmark.seal.fill" : "info.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(on ? Palette.greenText : Palette.ter)
                        .padding(.top, 1)
                    Text(note)
                        .font(AppFont.body(13, .bold))
                        .foregroundStyle(on ? Palette.greenText : Palette.sub)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(on ? Palette.greenSoft : Palette.page, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .background(Palette.card, in: shape)
        .overlay(shape.strokeBorder(on ? Palette.gold : Palette.cardBorder, lineWidth: 2))
        .background(shape.fill(on ? Palette.goldDark.opacity(0.55) : Palette.cardBorder).offset(y: 4))
        .padding(.bottom, 4)
    }
}

/// Date + exact-hour picker with an explanatory banner.
struct ScheduleEditor: View {
    @Binding var date: Date
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings

    private var hour: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: date) },
            set: { date = Calendar.current.date(bySettingHour: $0, minute: 0, second: 0, of: date) ?? date }
        )
    }

    private var day: Binding<Date> {
        Binding(
            get: { date },
            set: { newDay in
                let h = Calendar.current.component(.hour, from: date)
                date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: newDay) ?? newDay
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t.dateTime)
                .font(.eyebrow)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Palette.sub)
                .padding(.horizontal, 6)

            CardSection {
                HStack {
                    Text(t.dateLabel).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
                    Spacer()
                    DatePicker("", selection: day, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                        .labelsHidden()
                        .tint(Palette.brand)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .overlay(alignment: .bottom) { Rectangle().fill(Palette.sep).frame(height: 1).padding(.leading, 16) }

                HStack {
                    Text(t.timeLabel).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
                    Spacer()
                    Picker("", selection: hour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .tint(Palette.brandText)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
            }

            if date <= .now {
                Banner(text: t.pastDate, style: .error).padding(.horizontal, 4)
            } else {
                Banner(text: String(format: t.drawDateTimeInfo, DrawDateFormat.long(date, language: settings.language)))
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Step 2/2 — organizer details, then `POST /draws/dynamic`.
struct InviteOrganizerView: View {
    @Binding var path: [DrawsRoute]
    @Bindable var draft: InviteDraft
    var onCreated: (DynamicDrawResponse) -> Void

    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings
    @Environment(SessionStore.self) private var session

    @State private var showErrors = false
    @State private var isLoading = false
    @State private var serverError: String?

    var body: some View {
        let errors = showErrors ? draft.validationErrors(t) : [:]
        StepScaffold(step: t.step2of2, stepIndex: 2, title: t.yourDetails, subtitle: t.yourDetailsSub, mood: .invite) {
            VStack(spacing: 12) {
                if let serverError {
                    Banner(text: serverError, style: .error)
                }
                HStack(alignment: .top, spacing: 12) {
                    FormField(label: t.firstName, text: $draft.firstName, placeholder: t.firstNamePh, kind: .name,
                              isRequired: true, error: errors[.firstName])
                    FormField(label: t.lastName, text: $draft.lastName, placeholder: t.lastNamePh, kind: .name,
                              isRequired: true, error: errors[.lastName])
                }
                FormField(label: t.email, text: $draft.email, placeholder: t.emailPh, kind: .email,
                          isRequired: true, error: errors[.email])
                if draft.requireAddress {
                    FormField(label: t.address, text: $draft.address, placeholder: t.addressPh,
                              isRequired: true, error: errors[.address])
                }
                if draft.requirePhone {
                    FormField(label: t.phone, text: $draft.phone, placeholder: t.phonePh, kind: .phone,
                              isRequired: true, error: errors[.phone])
                }
            }
            .padding(.horizontal, 4)
        } bottom: {
            Button(action: submit) {
                Label(t.saveDetails, systemImage: "square.and.arrow.up")
            }
                .buttonStyle(GoldButtonStyle(isLoading: isLoading))
                .disabled(isLoading)
                .accessibilityIdentifier("invite.submit")
        }
    }

    private func submit() {
        showErrors = true
        serverError = nil
        guard draft.validationErrors(t).isEmpty else { return }
        if draft.scheduleEnabled && draft.drawDate <= .now {
            serverError = t.pastDate
            return
        }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let response = try await session.api.send(API.createDynamicDraw(draft.makeRequest(language: settings.language)))
                onCreated(response)
            } catch {
                serverError = error.userMessage(t)
            }
        }
    }
}
