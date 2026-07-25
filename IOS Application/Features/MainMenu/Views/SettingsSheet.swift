import SwiftUI

struct SettingsSheet: View {
    @Binding var roundLength: Int

    private let options = [30, 60, 90]

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Light It Up Round")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.cyan)

                Picker("Round Length", selection: $roundLength) {
                    ForEach(options, id: \.self) { option in
                        Text("\(option)s").tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text("Shorter rounds ramp faster. Longer rounds keep the final level running longer.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()
            }
            .padding(24)
        }
    }
}
