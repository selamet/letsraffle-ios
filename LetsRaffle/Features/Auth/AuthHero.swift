import SwiftUI

/// Red header shared by login / register / forgot password with Santa on the right.
/// Santa holds his list and covers his eyes while a password is being typed.
struct AuthScaffold<Content: View>: View {
    var mood: SantaMood
    var script: String
    var subtitle: String
    var trailing: AnyView? = nil
    var bubble: String? = nil
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ChristmasBackdrop(garland: true, pines: false)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                SnowFriends(fill: Palette.page, height: 84)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .ignoresSafeArea(.keyboard)
            VStack(spacing: 0) {
                HStack {
                    // The string runs up behind the status bar, as if hanging from the top edge.
                    OrnamentBackButton(stringLength: 50) { dismiss() }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.top, -46)
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(script)
                            .font(AppFont.script(50))
                            .foregroundStyle(Palette.goldLight)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(subtitle)
                            .font(AppFont.body(14, .bold))
                            .foregroundStyle(Palette.snow.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 22)
                    Spacer(minLength: 0)
                    ZStack(alignment: .topLeading) {
                        SantaAvatar(size: 140, mood: mood)
                            .id(mood)
                            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
                        if let bubble {
                            Text(bubble)
                                .font(AppFont.display(13))
                                .foregroundStyle(Palette.brandText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Palette.snow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
                                .offset(x: -70, y: 8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.35), value: mood)
                }
                .overlay(alignment: .topTrailing) {
                    if let trailing { trailing.padding(.trailing, 14) }
                }
                .padding(.leading, 22)
                .padding(.trailing, 4)
                .padding(.top, 2)

                // The foil card itself stays put; only what is inside it scrolls.
                ScrollView {
                    content
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .scrollDismissesKeyboard(.interactively)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(8)
                .foilCard(radius: 30)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
    }
}

/// Segmented "Giriş yap / Kayıt ol" switch at the top of the auth sheet.
struct AuthSegment: View {
    enum Tab { case login, register }
    let selected: Tab
    var onSelect: (Tab) -> Void
    @Environment(\.strings) private var t

    var body: some View {
        HStack(spacing: 4) {
            item(.login, t.loginBtn)
            item(.register, t.register)
        }
        .padding(4)
        .background(Color(light: 0xF3E6D6, dark: 0x3A2224), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func item(_ tab: Tab, _ title: String) -> some View {
        let on = tab == selected
        return Button {
            if !on { onSelect(tab) }
        } label: {
            Text(title)
                .font(AppFont.body(15, .bold))
                .foregroundStyle(on ? Palette.brandText : Palette.sub)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if on {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Palette.card)
                            .shadow(color: Color(hex: 0x6E0D12, alpha: 0.1), radius: 6, y: 3)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
