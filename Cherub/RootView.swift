import SwiftUI
import Combine

struct RootView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var store: CherubStore

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)

            CycleView()
                .tabItem { Label("Cycle", systemImage: "circle.dotted") }
                .tag(1)

            MoonView()
                .tabItem { Label("Moon", systemImage: "moon") }
                .tag(2)

            LogView()
                .tabItem { Label("Log", systemImage: "book.closed") }
                .tag(3)

            PatternsView()
                .tabItem { Label("Patterns", systemImage: "chart.bar") }
                .tag(4)
        }
        .tint(.cherubBurgundy)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now in
            store.refreshPatternClock(now: now)
        }
    }
}
