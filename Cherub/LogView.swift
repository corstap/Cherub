import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: CherubStore
    @State private var selectedDate = Date()
    @State private var draft = DailyLog.empty()
    @State private var savedMessage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CherubHeader(subtitle: "Daily Log")

                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(.cherubBurgundy)
                        .cherubCard()

                    VStack(alignment: .leading, spacing: 20) {
                        SectionTitle(text: "How are you feeling?")
                        ratingRow("Energy", icon: "sun.max", value: $draft.energy, tint: .cherubGold)
                        ratingRow("Mood", icon: "face.smiling", value: $draft.mood, tint: .cherubRose)
                        ratingRow("Sleep", icon: "moon.zzz", value: $draft.sleep, tint: .cherubSage)
                        ratingRow("Creativity", icon: "sparkles", value: $draft.creativity, tint: .cherubBurgundy)
                        ratingRow("Stress", icon: "bolt", value: $draft.stress, tint: .cherubRose)
                        ratingRow("Symptoms", icon: "heart", value: $draft.symptoms, tint: .cherubBurgundy)
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Notes")
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(Color.black.opacity(0.025))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .cherubCard()

                    Button {
                        draft.date = selectedDate
                        store.save(draft)
                        savedMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { savedMessage = false }
                    } label: {
                        Text(savedMessage ? "Saved" : "Save today’s log")
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
            .onAppear { draft = store.log(for: selectedDate) }
            .onChange(of: selectedDate) { _, newDate in
                draft = store.log(for: newDate)
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
