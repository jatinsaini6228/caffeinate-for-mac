import Foundation
import WidgetKit

public struct CaffeinateStateData: Codable, Equatable {
    public var isActive: Bool
    public var mode: String            // "display" or "system"
    public var durationTitle: String
    public var remainingSeconds: Double
    public var expirationTimestamp: Double?
    public var batteryLevel: Int?
    public var isCharging: Bool
    public var isOnACPower: Bool
    public var lowBatteryCutoffEnabled: Bool
    public var lastUpdated: Double

    public init(
        isActive: Bool = false,
        mode: String = "display",
        durationTitle: String = "Indefinitely",
        remainingSeconds: Double = 0,
        expirationTimestamp: Double? = nil,
        batteryLevel: Int? = nil,
        isCharging: Bool = false,
        isOnACPower: Bool = true,
        lowBatteryCutoffEnabled: Bool = true,
        lastUpdated: Double = Date().timeIntervalSince1970
    ) {
        self.isActive = isActive
        self.mode = mode
        self.durationTitle = durationTitle
        self.remainingSeconds = remainingSeconds
        self.expirationTimestamp = expirationTimestamp
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.isOnACPower = isOnACPower
        self.lowBatteryCutoffEnabled = lowBatteryCutoffEnabled
        self.lastUpdated = lastUpdated
    }
}

/// Manages cross-process state persistence between the main application and macOS WidgetKit extension.
public final class SharedStateManager {
    public static let shared = SharedStateManager()
    public static let notificationName = Notification.Name("com.caffeinate.stateChanged")

    private let fileManager = FileManager.default
    private let stateURL: URL

    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let caffeinateDir = appSupport.appendingPathComponent("Caffeinate", isDirectory: true)

        try? fileManager.createDirectory(at: caffeinateDir, withIntermediateDirectories: true)
        self.stateURL = caffeinateDir.appendingPathComponent("state.json")
    }

    public func save(state: CaffeinateStateData) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: stateURL, options: .atomic)

            // Notify WidgetKit and distributed listeners
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name(rawValue: "com.caffeinate.stateChanged"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save Caffeinate state: \(error)")
        }
    }

    public func load() -> CaffeinateStateData {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(CaffeinateStateData.self, from: data) else {
            return CaffeinateStateData()
        }
        return state
    }
}
