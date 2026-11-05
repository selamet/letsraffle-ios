import SwiftUI

@main
struct SantasDrawApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(\.strings, settings.strings)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Palette.brand)
        }
    }
}
