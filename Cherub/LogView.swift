import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: CherubStore
    @State private var savedMessage = false
    @State private var saveFeedbackID = UUID()

    private var draft: DailyLog { store.selectedLogDraft }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CherubHeader(subtitle: "Daily Log")

                    SharedDateNavigator()

                    VStack(alignment: .leading, spacing: 20) {
                        SectionTitle(text: "How are you feeling?")
                        ratingRow("Energy", icon: "sun.max", value: $store.selectedLogDraft.energy, tint: .cherubGold)
                        ratingRow("Mood", icon: "face.smiling", value: $store.selectedLogDraft.mood, tint: .cherubRose)
                        ratingRow("Sleep", icon: "moon.zzz", value: $store.selectedLogDraft.sleep, tint: .cherubSage)
                        ratingRow("Creativity", icon: "sparkles", value: $store.selectedLogDraft.creativity, tint: .cherubBurgundy)
                        ratingRow("Stress", icon: "bolt", value: $store.selectedLogDraft.stress, tint: .cherubRose)
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 18) {
                        SectionTitle(text: "Physical")
                        Text("Flow")
                            .font(.subheadline.weight(.semibold))
                        HStack(spacing: 8) {
                            ForEach(MenstrualFlow.allCases) { flow in
                                Button {
                                    store.selectedLogDraft.flow = flow
                                } label: {
                                    Text(flow.title)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundStyle(draft.flow == flow ? Color.white : Color.cherubInk)
                                        .background(draft.flow == flow ? Color.cherubBurgundy : Color.black.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Flow: \(flow.title)")
                                .accessibilityValue(draft.flow == flow ? "Selected" : "Not selected")
                            }
                        }
                        ratingRow("Aches & Cramps", icon: "heart", value: $store.selectedLogDraft.symptoms, tint: .cherubBurgundy)
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Notes")
                        TextEditor(text: $store.selectedLogDraft.notes)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(Color.black.opacity(0.025))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .cherubCard()

                    Button {
                        store.save(draft)
                        savedMessage = true
                        let feedbackID = UUID()
                        saveFeedbackID = feedbackID
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            if saveFeedbackID == feedbackID { savedMessage = false }
                        }
                    } label: {
                        Text(savedMessage ? "Saved" : "Save log")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.cherubBurgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: store.selectedDate) { _, _ in
                savedMessage = false
                saveFeedbackID = UUID()
            }
        }
    }

    private func ratingRow(_ title: String, icon: String, value: Binding<Int>, tint: Color) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 110, alignment: .leading)
            Spacer()
            RatingDots(value: value, tint: tint)
        }
    }
}
