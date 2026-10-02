import Foundation

public enum DurationOption: Equatable, Hashable {
    case indefinite
    case minutes(Int)

    public var title: String {
        switch self {
        case .indefinite:
            return "Indefinitely"
        case .minutes(let mins):
            if mins < 60 {
                return "\(mins) Minutes"
            } else {
                let hours = mins / 60
                let remMins = mins % 60
                if remMins == 0 {
                    return "\(hours) \(hours == 1 ? "Hour" : "Hours")"
                } else {
                    return "\(hours)h \(remMins)m"
                }
            }
        }
    }

    public var seconds: TimeInterval? {
        switch self {
        case .indefinite:
            return nil
        case .minutes(let mins):
            return TimeInterval(mins * 60)
        }
    }

    public static let standardPresets: [DurationOption] = [
        .indefinite,
        .minutes(15),
        .minutes(30),
        .minutes(60),
        .minutes(120),
        .minutes(240)
    ]
}

/// Coordinates session durations, countdown timers, and auto-expiration callbacks.
public final class TimerManager {
    public static let shared = TimerManager()

    public private(set) var activeDuration: DurationOption = .indefinite
    public private(set) var expirationDate: Date?
    public private(set) var remainingSeconds: TimeInterval = 0

    public var onTick: ((TimeInterval) -> Void)?
    public var onExpire: (() -> Void)?

    private var timer: Timer?

    public var isTimerRunning: Bool {
        return timer != nil && expirationDate != nil
    }

    public init() {}

    deinit {
        stopTimer()
    }

    public func start(duration: DurationOption) {
        stopTimer()
        activeDuration = duration

        guard let totalSeconds = duration.seconds else {
            // Indefinite mode
            expirationDate = nil
            remainingSeconds = 0
            return
        }

        expirationDate = Date().addingTimeInterval(totalSeconds)
        remainingSeconds = totalSeconds

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
        expirationDate = nil
        remainingSeconds = 0
    }

    private func tick() {
        guard let exp = expirationDate else {
            stopTimer()
            return
        }

        let remaining = exp.timeIntervalSinceNow
        if remaining <= 0 {
            remainingSeconds = 0
            stopTimer()
            DispatchQueue.main.async { [weak self] in
                self?.onExpire?()
            }
        } else {
            remainingSeconds = remaining
            DispatchQueue.main.async { [weak self] in
                self?.onTick?(remaining)
            }
        }
    }

    public func formattedRemainingTime() -> String {
        switch activeDuration {
        case .indefinite:
            return "Indefinite"
        case .minutes:
            guard remainingSeconds > 0 else { return "00:00" }
            let totalSecs = Int(remainingSeconds.rounded(.up))
            let hours = totalSecs / 3600
            let minutes = (totalSecs % 3600) / 60
            let seconds = totalSecs % 60

            if hours > 0 {
                return String(format: "%dh %02dm", hours, minutes)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
}
