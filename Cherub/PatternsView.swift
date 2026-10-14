import SwiftUI

struct PatternsView: View {
    @EnvironmentObject private var store: CherubStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CherubHeader(subtitle: "Your Patterns")

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Key Insights")
                        Text("These are calculated from the entries stored on this iPhone.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(store.insights()) { insight in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle().fill(Color.cherubBurgundy.opacity(0.1)).frame(width: 46, height: 46)
                                Image(systemName: insight.icon).foregroundStyle(Color.cherubBurgundy)
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(insight.title)
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                Text(insight.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .cherubCard()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing leaves the app")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                        Text("This first build has no account, analytics SDK or server. Your logs are saved locally with UserDefaults on the device running Cherub.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
}
