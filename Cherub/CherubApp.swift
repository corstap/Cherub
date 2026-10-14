import SwiftUI

@main
struct CherubApp: App {
    @StateObject private var store = CherubStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.refreshPatternClock() }
                }
        }
    }
}
