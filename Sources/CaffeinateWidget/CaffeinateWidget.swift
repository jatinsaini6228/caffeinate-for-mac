import WidgetKit
import SwiftUI

public struct CaffeinateWidgetEntry: TimelineEntry {
    public let date: Date
    public let isActive: Bool
    public let mode: String
    public let durationTitle: String
    public let remainingSeconds: Double
    public let batteryLevel: Int?
    public let isCharging: Bool

    public init(
        date: Date = Date(),
        isActive: Bool = false,
        mode: String = "display",
        durationTitle: String = "Indefinitely",
        remainingSeconds: Double = 0,
        batteryLevel: Int? = 80,
        isCharging: Bool = false
    ) {
        self.date = date
        self.isActive = isActive
        self.mode = mode
        self.durationTitle = durationTitle
        self.remainingSeconds = remainingSeconds
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
    }
}

public struct CaffeinateTimelineProvider: TimelineProvider {
    public typealias Entry = CaffeinateWidgetEntry

    public func placeholder(in context: Context) -> CaffeinateWidgetEntry {
        CaffeinateWidgetEntry(isActive: true, mode: "display", durationTitle: "Indefinitely", batteryLevel: 85, isCharging: false)
    }

    public func getSnapshot(in context: Context, completion: @escaping (CaffeinateWidgetEntry) -> Void) {
        completion(loadCurrentState())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<CaffeinateWidgetEntry>) -> Void) {
        let entry = loadCurrentState()
        // Refresh periodically (e.g. every 15 minutes) or when reloaded by WidgetCenter
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentState() -> CaffeinateWidgetEntry {
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let stateURL = appSupport.appendingPathComponent("Caffeinate/state.json")
            if let data = try? Data(contentsOf: stateURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let isActive = (json["isActive"] as? Bool) ?? false
                let mode = (json["mode"] as? String) ?? "display"
                let duration = (json["durationTitle"] as? String) ?? "Indefinitely"
                let remaining = (json["remainingSeconds"] as? Double) ?? 0
                let battery = json["batteryLevel"] as? Int
                let charging = (json["isCharging"] as? Bool) ?? false

                return CaffeinateWidgetEntry(
                    date: Date(),
                    isActive: isActive,
                    mode: mode,
                    durationTitle: duration,
                    remainingSeconds: remaining,
                    batteryLevel: battery,
                    isCharging: charging
                )
            }
        }
        return CaffeinateWidgetEntry()
    }
}

struct CaffeinateWidgetEntryView: View {
    var entry: CaffeinateTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "caffeinate://toggle"))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(entry.isActive ? Color.orange.opacity(0.2) : Color.gray.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: entry.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .foregroundColor(entry.isActive ? .orange : .secondary)
                        .font(.system(size: 15, weight: .bold))
                }

                Spacer()

                Circle()
                    .fill(entry.isActive ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
            }

            Spacer()

            Text(entry.isActive ? "AWAKE" : "IDLE")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(entry.isActive ? .green : .secondary)

            Text(entry.isActive ? (entry.mode == "display" ? "Display & System" : "System Only") : "Tap to activate")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            if let battery = entry.batteryLevel {
                HStack(spacing: 4) {
                    Image(systemName: entry.isCharging ? "battery.100.bolt" : "battery.75")
                        .font(.system(size: 10))
                    Text("\(battery)%")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .widgetBackground {
            Color.clear
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(entry.isActive ? Color.orange.opacity(0.25) : Color.gray.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: entry.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                            .foregroundColor(entry.isActive ? .orange : .secondary)
                            .font(.system(size: 18, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Caffeinate")
                            .font(.system(size: 15, weight: .bold))
                        Text(entry.isActive ? "Active (Sleep Prevented)" : "Inactive")
                            .font(.system(size: 11))
                            .foregroundColor(entry.isActive ? .green : .secondary)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 10))
                    Text("Tap widget to toggle")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
            }

            Divider()

            // Right Column
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MODE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(entry.mode == "display" ? "Display & System" : "System Only")
                        .font(.system(size: 12, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("DURATION")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(entry.durationTitle)
                        .font(.system(size: 12, weight: .medium))
                }

                if let battery = entry.batteryLevel {
                    HStack(spacing: 4) {
                        Image(systemName: entry.isCharging ? "battery.100.bolt" : "battery.75")
                            .font(.system(size: 11))
                        Text("Battery: \(battery)%")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetBackground {
            Color.clear
        }
    }
}

extension View {
    @ViewBuilder
    func widgetBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(macOS 14.0, *) {
            self.containerBackground(for: .widget) {
                content()
            }
        } else {
            self.background(content())
        }
    }
}

@main
struct CaffeinateWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaffeinateWidget()
    }
}

struct CaffeinateWidget: Widget {
    let kind: String = "CaffeinateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeinateTimelineProvider()) { entry in
            CaffeinateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Caffeinate")
        .description("Quickly monitor and toggle macOS sleep prevention.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
