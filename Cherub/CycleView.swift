import SwiftUI

struct CycleView: View {
    @EnvironmentObject private var store: CherubStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    CherubHeader(subtitle: "Your Cycle")
                    SharedDateNavigator()
                    CycleWheelView(size: 260)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "\(store.phase().rawValue) Phase")
                        Text("Day \(store.cycleDay()) · \(store.phase().archetype)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cherubBurgundy)
                        Text(store.phase().description)
                            .foregroundStyle(Color.cherubInk.opacity(0.8))
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "At a Glance")
                        infoRow("Average cycle", "\(store.profile.averageCycleLength) days")
                        Divider()
                        infoRow("Average period", "\(store.profile.averagePeriodLength) days")
                        Divider()
                        infoRow("Next period", store.nextPeriodDate().formatted(date: .abbreviated, time: .omitted))
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Cycle Phases")
                        ForEach(CyclePhase.allCases, id: \.self) { phase in
                            HStack(alignment: .top, spacing: 12) {
                                Circle().fill(phase.color).frame(width: 13, height: 13).padding(.top, 4)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(phase.rawValue).font(.headline)
                                    Text(phase.description).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .cherubCard()
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
