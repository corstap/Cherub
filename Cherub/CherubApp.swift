import SwiftUI

@main
struct CherubApp: App {
    @StateObject private var store = CherubStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
