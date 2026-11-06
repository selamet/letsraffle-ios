import Contacts
import ContactsUI
import SwiftUI

/// Presents the system contact picker (no Contacts permission required) and
/// maps the chosen contact into a participant draft.
struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onPick: (PickedContact) -> Void

    struct PickedContact {
        var firstName: String
        var lastName: String
        var email: String?
        var phone: String?
        var address: String?
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        context.coordinator.parent = self
        guard isPresented, host.presentedViewController == nil else { return }
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        DispatchQueue.main.async { host.present(picker, animated: true) }
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker

        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.isPresented = false
            parent.onPick(Self.map(contact))
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }

        static func map(_ contact: CNContact) -> PickedContact {
            let address = contact.postalAddresses.first.map {
                CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
            }
            return PickedContact(
                firstName: contact.givenName,
                lastName: contact.familyName,
                email: contact.emailAddresses.first.map { String($0.value) },
                phone: contact.phoneNumbers.first?.value.stringValue,
                address: address
            )
        }
    }
}
