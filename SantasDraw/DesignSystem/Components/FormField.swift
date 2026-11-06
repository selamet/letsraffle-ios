import SwiftUI

/// Labelled 50pt text field matching the design's form inputs.
struct FormField: View {
    enum Kind { case text, email, password, phone, name }

    let label: String
    @Binding var text: String
    var placeholder = ""
    var kind: Kind = .text
    var isRequired = false
    var hint: String?
    var error: String?

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
            .foregroundStyle(Palette.sub)
            .padding(.horizontal, 4)

            HStack {
                input
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.text)
                    .focused($focused)
                if kind == .password {
                    Button {
                        revealed.toggle()
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .foregroundStyle(Palette.ter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: focused || error != nil ? 1.5 : 1)
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }

            if let message = error ?? hint {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(error != nil ? Palette.brandText : Palette.sub)
                    .padding(.horizontal, 4)
            }
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

/// "—— or ——" separator.
struct OrDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Palette.sep).frame(height: 1)
            Text(title).font(.system(size: 13)).foregroundStyle(Palette.ter)
            Rectangle().fill(Palette.sep).frame(height: 1)
        }
    }
}
