import SwiftUI
import UIKit
import ObjectiveC

/// Per-screen status bar style. SwiftUI has no API for this, so the hosting
/// controllers' `preferredStatusBarStyle` is redirected to a shared value
/// that screens set when they appear (light on red headers, dark on cream).
@MainActor
enum StatusBar {
    private(set) static var style: UIStatusBarStyle = .lightContent
    private static var patched = Set<ObjectIdentifier>()

    static func set(_ newStyle: UIStatusBarStyle) {
        style = newStyle
        refresh()
    }

    private static func refresh() {
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                var controller = window.rootViewController
                while let current = controller {
                    patchIfNeeded(current)
                    current.setNeedsStatusBarAppearanceUpdate()
                    controller = current.presentedViewController
                }
            }
        }
    }

    private static func patchIfNeeded(_ controller: UIViewController) {
        let cls: AnyClass = type(of: controller)
        let id = ObjectIdentifier(cls)
        guard !patched.contains(id), NSStringFromClass(cls).contains("Hosting") else { return }
        patched.insert(id)
        let selector = #selector(getter: UIViewController.preferredStatusBarStyle)
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else { return }
        let block: @convention(block) (AnyObject) -> Int = { _ in
            MainActor.assumeIsolated { StatusBar.style.rawValue }
        }
        class_replaceMethod(cls, selector, imp_implementationWithBlock(block), method_getTypeEncoding(method))
    }
}

extension View {
    /// Sets the status bar style while this screen is on top.
    func statusBarStyle(_ style: UIStatusBarStyle) -> some View {
        onAppear { StatusBar.set(style) }
            .onChange(of: style) { _, newStyle in StatusBar.set(newStyle) }
    }
}
