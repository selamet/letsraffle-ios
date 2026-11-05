import Foundation

/// DEBUG-only deep entry used for visual QA: launch with `-route <name>`.
enum DebugRoute {
    static var current: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "route")
        #else
        nil
        #endif
    }
}
