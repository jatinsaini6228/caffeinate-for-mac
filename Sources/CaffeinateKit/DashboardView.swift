import SwiftUI

public struct DashboardView: View {
    @ObservedObject var state = AppState.shared
    public var onClose: (() -> Void)?

    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            HStack(spacing: 16) {
                appLogoView
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: state.isActive ? Color.orange.opacity(0.4) : Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Caffeinate")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        // Status Badge
                        HStack(spacing: 5) {
                            Circle()
                                .fill(state.isActive ? Color.green : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text(state.isActive ? "AWAKE" : "IDLE")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(state.isActive ? .green : .secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(state.isActive ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                        )
                    }

                    Text("Keep your Mac awake without touching settings")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Divider()
                .padding(.horizontal, 24)

            // MARK: - Primary Big Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    state.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(state.isActive ? Color.orange : Color.secondary.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .shadow(color: state.isActive ? Color.orange.opacity(0.6) : Color.clear, radius: 10)

                        Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(state.isActive ? .white : .primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.isActive ? "Caffeinate Active" : "Caffeinate Inactive")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if state.isActive && !state.remainingFormatted.isEmpty {
                            Text("Session ending in \(state.remainingFormatted)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.orange)
                        } else {
                            Text(state.isActive ? "Click to deactivate and allow normal sleep" : "Click to activate sleep prevention")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: state.isActive ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 28))
                        .foregroundColor(state.isActive ? .green : .secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(state.isActive ? Color.orange.opacity(0.12) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(state.isActive ? Color.orange.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            // MARK: - Sleep Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("SLEEP PREVENTION MODE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    modeButton(
                        title: "Display & System",
                        subtitle: "Screen stays awake",
                        icon: "display",
                        mode: .display
                    )
                    modeButton(
                        title: "System Only",
                        subtitle: "Screen can turn off",
                        icon: "bolt.fill",
                        mode: .system
                    )
                }
            }
            .padding(.horizontal, 24)

            // MARK: - Duration Presets
            VStack(alignment: .leading, spacing: 8) {
                Text("DURATION PRESETS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                    ForEach(DurationOption.standardPresets, id: \.self) { preset in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                state.setDuration(preset)
                            }
                        }) {
                            Text(preset.title)
                                .font(.system(size: 12, weight: state.duration == preset ? .semibold : .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(state.duration == preset ? Color.accentColor : Color.primary.opacity(0.05))
                                )
                                .foregroundColor(state.duration == preset ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)

            // MARK: - Battery & Protection
            HStack(spacing: 12) {
                Image(systemName: state.batteryStatus.isCharging ? "battery.100.bolt" : "battery.75")
                    .font(.system(size: 20))
                    .foregroundColor(state.batteryStatus.isCharging ? .green : .primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Battery: \(state.batteryStatus.descriptionText)")
                        .font(.system(size: 12, weight: .medium))

                    Toggle("Auto-disable below 20% battery", isOn: Binding(
                        get: { state.isLowBatteryCutoffEnabled },
                        set: { state.setLowBatteryCutoff($0) }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 24)

            Spacer()

            // MARK: - Footer
            HStack {
                Toggle("Show on launch", isOn: Binding(
                    get: { state.showOnLaunch },
                    set: { state.setShowOnLaunch($0) }
                ))
                .toggleStyle(.checkbox)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                Spacer()

                Button("Minimize to Menu Bar") {
                    onClose?()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 440, height: 530)
        .background(VisualEffectView().ignoresSafeArea())
    }

    private var appLogoView: some View {
        Group {
            if let path = Bundle.main.path(forResource: "app_logo", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let nsImage = NSImage(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/app_logo.png").path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func modeButton(title: String, subtitle: String, icon: String, mode: PowerManager.SleepMode) -> some View {
        let isSelected = state.currentMode == mode
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                state.setMode(mode)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// Transparent frosted glass vibrancy view
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
