import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CherubStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle") {
                    DatePicker("Last period started", selection: $store.profile.lastPeriodStart, displayedComponents: .date)
                    Stepper("Average cycle: \(store.profile.averageCycleLength) days", value: $store.profile.averageCycleLength, in: 20...45)
                    Stepper("Average period: \(store.profile.averagePeriodLength) days", value: $store.profile.averagePeriodLength, in: 1...10)
                }

                Section("Privacy") {
                    Label("No account required", systemImage: "person.crop.circle.badge.xmark")
                    Label("Logs stay on this device", systemImage: "iphone")
                    Text("Apple Health is intentionally not connected in this first build. That can be added later as an optional permission.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    Text("Cherub combines menstrual-cycle tracking, lunar information and your own daily observations. Symbolic lunar and astrology notes are for reflection, not medical advice.")
                        .font(.footnote)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cherubBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cherubBurgundy)
                }
            }
        }
    }
}
