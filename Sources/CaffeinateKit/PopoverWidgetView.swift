import SwiftUI

/// Compact interactive widget popover attached to the menu bar status icon.
public struct PopoverWidgetView: View {
    @ObservedObject var state = AppState.shared
    public var onOpenDashboard: (() -> Void)?

    public init(onOpenDashboard: (() -> Void)? = nil) {
        self.onOpenDashboard = onOpenDashboard
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .foregroundColor(state.isActive ? .orange : .primary)
                    Text("Caffeinate")
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                Text(state.isActive ? "AWAKE" : "IDLE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(state.isActive ? .green : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(state.isActive ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12)))
            }

            // Quick Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.toggle()
                }
            }) {
                HStack {
                    Image(systemName: state.isActive ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 16))
                        .foregroundColor(state.isActive ? .green : .secondary)

                    Text(state.isActive ? "Deactivate Sleep Prevention" : "Activate Sleep Prevention")
                        .font(.system(size: 12, weight: .medium))

                    Spacer()

                    if state.isActive && !state.remainingFormatted.isEmpty {
                        Text(state.remainingFormatted)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(state.isActive ? Color.orange.opacity(0.15) : Color.primary.opacity(0.05))
                )
            }
            .buttonStyle(.plain)

            // Mode Selector
            HStack(spacing: 6) {
                modeChip(title: "Display & System", mode: .display)
                modeChip(title: "System Only", mode: .system)
            }

            // Duration Presets (quick chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(DurationOption.standardPresets, id: \.self) { preset in
                        Button(action: {
                            state.setDuration(preset)
                        }) {
                            Text(preset.title)
                                .font(.system(size: 10, weight: state.duration == preset ? .semibold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(state.duration == preset ? Color.accentColor : Color.primary.opacity(0.06))
                                )
                                .foregroundColor(state.duration == preset ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: state.batteryStatus.isCharging ? "battery.100.bolt" : "battery.75")
                        .font(.system(size: 11))
                    Text(state.batteryStatus.descriptionText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Open Dashboard...") {
                    onOpenDashboard?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.accentColor)
            }
        }
        .padding(14)
        .frame(width: 290)
    }

    private func modeChip(title: String, mode: PowerManager.SleepMode) -> some View {
        let isSelected = state.currentMode == mode
        return Button(action: {
            state.setMode(mode)
        }) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
