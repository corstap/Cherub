# Cherub

Cherub is a local SwiftUI app for daily logging and exploring personal menstrual-cycle × lunar-cycle patterns. The app uses the existing Today, Cycle, Moon, Log, and Patterns tabs. There is no account or backend.

## Run in Xcode

Extract the whole project into a folder such as `~/Developer/Cherub`, then open `Cherub.xcodeproj` in Xcode. Select an iOS 17 or later simulator and run. For a physical device, select your development team in Signing & Capabilities. Open the Xcode project rather than `Package.swift`; the package is only for analysis tests.

## Patterns

The Patterns tab contains a four-by-eight Cycle × Moon matrix. Choose Energy, Mood, Sleep, Creativity, Stress, Aches & Cramps, Libido, or Flow. Each cell shows the average and number of days with that metric logged. Tap it to inspect:

- The overall moon comparison across menstrual phases.
- The comparison restricted to the same menstrual phase.
- Logged-day counts, menstrual/lunar cycle counts, and repeatability across matched cycles.

Missing ratings do not count as zero. Ratings use a 1–5 scale; sleep is a rating, not hours. Flow is an ordinal score: None = 0, Light = 1, Medium = 2, Heavy = 3. This score does not measure blood volume. Future entries are excluded, and browsing a past date limits analysis to that date.

### Evidence labels

- **Not enough data yet:** fewer than five rated days in either group, or fewer than two menstrual or two lunar cycles in either group.
- **No clear difference:** adequate repeated data, but the observed within-phase gap is smaller than 0.5 rating points (0.3 for Flow).
- **Possible pattern:** a larger gap with the minimum repeated data.
- **Stronger pattern:** at least 15 days and three lunar cycles per group, plus at least three matched menstrual cycles. Each matched cycle needs two days in both groups. The average cycle-level difference must exceed the threshold, agree with the pooled difference, have an approximate 95% Student-t range excluding zero, and have the same direction in at least 75% of matched cycles.

These thresholds are conservative product rules, not clinical validation. Comparisons are exploratory and involve multiple combinations. Chance, selective logging, and other factors can explain an association. Menstrual phases are estimated from the user's settings, and lunar phases use Cherub's existing approximate calculation. Cycle-level contrasts reduce treating adjacent daily entries as independent; they do not eliminate all dependencies or biases.

Newly saved logs preserve their estimated cycle phase, cycle start, and moon phase. Earlier logs without these fields use current cycle settings; the app reports how many days were inferred. Existing logs remain readable, and Libido starts unlogged.

### Watch This Pattern

Tap **Watch This Pattern** on a comparison to save a local watch. A watch created during its matching window waits until that window ends before prompting again. Cherub estimates the next matching date and surfaces a reminder on Today and Patterns when the combination recurs. Logging the watched metric clears that day's reminder; the watch stays active for future matching days. Remove it from Patterns to stop watching.

Reminders appear inside the app while it is open or when it returns to the foreground. They do not schedule system notifications. Forecasts use the current cycle settings and can change when those settings change. Personal comparisons use only saved logs; traditional moon associations remain separate.

## Verify

Run `swift test` from this directory with Swift 5.9 or later to test the actual Foundation models and analysis engine. The tests cover missing/legacy data, Libido, Flow, counts, menstrual-phase confounding, evidence thresholds, saved context, future-date filtering, and watch recurrence/completion.

The Swift package does not build the iOS interface. Verify the app separately in Xcode: save a log with Libido, browse dates, switch matrix metrics, inspect a cell, add/remove a watch, and reopen the app to confirm persistence. With little data, expect empty cells and cautious evidence labels; no example entries are injected into the app.
