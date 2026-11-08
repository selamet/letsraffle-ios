import SwiftUI

/// "Gift tag" text field: white, 16pt corners, warm border, red focus ring.
struct FormField: View {
    enum Kind { case text, email, password, phone, name }

    let label: String
    @Binding var text: String
    var placeholder = ""
    var kind: Kind = .text
    var isRequired = false
    var hint: String?
    var error: String?
    /// SF Symbol shown inside the field; defaults per kind.
    var icon: String? = nil
    /// Reports focus changes (e.g. Santa covers his eyes on password fields).
    var onFocusChange: ((Bool) -> Void)? = nil

    @FocusState private var focused: Bool
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(label)
                if isRequired {
                    Text("*").foregroundStyle(Palette.brandText)
                }
            }
            .font(.fieldLabel)
            .foregroundStyle(Color(light: 0x5B3A3A, dark: 0xE8D2C8))
            .padding(.horizontal, 2)

            HStack(spacing: 10) {
                if let symbol = icon ?? defaultIcon {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.brand)
                        .frame(width: 22)
                }
                input
                    .font(AppFont.body(16, .bold))
                    .foregroundStyle(Palette.text)
                    .focused($focused)
                if kind == .password {
                    Button {
                        revealed.toggle()
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .foregroundStyle(Palette.ter)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(revealed ? "Hide password" : "Show password")
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, kind == .password ? 4 : 16)
            .frame(height: 54)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
            }
            .background {
                if focused {
                    RoundedRectangle(cornerRadius: Radius.field + 4, style: .continuous)
                        .fill(Palette.brand.opacity(0.12))
                        .padding(-4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
            .onChange(of: focused) { _, value in onFocusChange?(value) }

            if let message = error ?? hint {
                Text(message)
                    .font(AppFont.body(12, .bold))
                    .foregroundStyle(error != nil ? Palette.brandText : Palette.sub)
                    .padding(.horizontal, 2)
            }
        }
    }

    private var defaultIcon: String? {
        switch kind {
        case .email: "envelope"
        case .password: "lock"
        case .phone: "phone"
        case .name, .text: nil
        }
    }

    private var borderColor: Color {
        if error != nil || focused { return Palette.brand }
        return Palette.fieldBorder
    }

    @ViewBuilder
    private var input: some View {
        let prompt = Text(placeholder).foregroundStyle(Palette.ter)
        switch kind {
        case .password where !revealed:
            SecureField("", text: $text, prompt: prompt)
                .textContentType(.password)
        case .password:
            TextField("", text: $text, prompt: prompt)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .email:
            TextField("", text: $text, prompt: prompt)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .phone:
            TextField("", text: $text, prompt: prompt)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        case .name:
            TextField("", text: $text, prompt: prompt)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .text:
            TextField("", text: $text, prompt: prompt)
        }
    }
}

/// "~~~~ veya ~~~~" separator with candy stripes.
struct OrDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            stripe
            Text(title).font(AppFont.body(13, .bold)).foregroundStyle(Palette.ter)
            stripe
        }
    }

    private var stripe: some View {
        Canvas { ctx, size in
            var x: CGFloat = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + 6, y: 0))
                p.addLine(to: CGPoint(x: x + 6, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Color(hex: 0xE8CFC0)))
                x += 12
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }
}

/// Candy-cane switch: striped red track when on, warm beige when off.
struct CandyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Button {
                withAnimation(.spring(duration: 0.3)) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? Color(hex: 0xD43A3F) : Color(light: 0xE7D8C6, dark: 0x4A3234))
                        .overlay {
                            if configuration.isOn {
                                Canvas { ctx, size in
                                    var x: CGFloat = -size.height
                                    while x < size.width {
                                        var p = Path()
                                        p.move(to: CGPoint(x: x, y: size.height))
                                        p.addLine(to: CGPoint(x: x + size.height, y: 0))
                                        p.addLine(to: CGPoint(x: x + size.height + 8, y: 0))
                                        p.addLine(to: CGPoint(x: x + 8, y: size.height))
                                        p.closeSubpath()
                                        ctx.fill(p, with: .color(Color(hex: 0xB91C1C)))
                                        x += 16
                                    }
                                }
                                .clipShape(Capsule())
                            }
                        }
                        .frame(width: 54, height: 32)
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
                        .padding(3)
                }
                .frame(minWidth: 54, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
        }
    }
}
