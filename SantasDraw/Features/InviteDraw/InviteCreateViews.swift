import SwiftUI

/// Common layout for multi-step forms: back button + step label, title, scrolling
/// content and a pinned bottom action.
struct StepScaffold<Content: View, Bottom: View>: View {
    var step: String?
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content
    @ViewBuilder var bottom: Bottom

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton { dismiss() }
                Spacer()
                if let step {
                    Text(step)
                        .font(.eyebrow)
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.brandText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Palette.chip, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.cardBorder).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(title: title, subtitle: subtitle, titleSize: 30)
                        .padding(.horizontal, 8)
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            bottom
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .background(
                    Palette.card
                        .shadow(color: Color(hex: 0x6E0D12, alpha: 0.08), radius: 15, y: -6)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Step 1/2 — optional settings and schedule.
struct InviteSettingsView: View {
    @Binding var path: [DrawsRoute]
    @Bindable var draft: InviteDraft
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings

    private var hours: [Int] { Array(0..<24) }

    var body: some View {
        StepScaffold(step: t.step1of2, title: t.settingsTitle, subtitle: t.settingsOptional) {
            CardSection {
                IconRow(icon: "mappin.and.ellipse", iconTint: Palette.amberText, iconBackground: Palette.amberSoft,
                        title: t.requireAddress, subtitle: t.requireAddressDesc, showsSeparator: true) {
                    Toggle(t.requireAddress, isOn: $draft.requireAddress).labelsHidden().toggleStyle(CandyToggleStyle())
                }
                IconRow(icon: "phone.fill", iconTint: Palette.amberText, iconBackground: Palette.amberSoft,
                        title: t.requirePhone, subtitle: t.requirePhoneDesc, showsSeparator: true) {
                    Toggle(t.requirePhone, isOn: $draft.requirePhone).labelsHidden().toggleStyle(CandyToggleStyle())
                }
                IconRow(icon: "calendar", iconTint: Palette.brandText, iconBackground: Palette.chip,
                        title: t.enableDrawDate, subtitle: t.drawDateEnabledDesc) {
                    Toggle(t.enableDrawDate, isOn: $draft.scheduleEnabled.animation()).labelsHidden().toggleStyle(CandyToggleStyle())
                }
            }

            if draft.scheduleEnabled {
                ScheduleEditor(date: $draft.drawDate)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                .buttonStyle(.primary)
                .accessibilityIdentifier("invite.continue")
        }
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
        StepScaffold(step: t.step2of2, title: t.yourDetails, subtitle: t.yourDetailsSub) {
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
