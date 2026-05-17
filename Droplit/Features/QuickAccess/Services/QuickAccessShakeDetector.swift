import CoreGraphics
import Foundation

final class QuickAccessShakeDetector {
    private var lastPoint: CGPoint?
    private var lastDirection: CGFloat = 0
    private var reversalCount = 0
    private var totalHorizontalDistance: CGFloat = 0
    private var windowStartTime: TimeInterval = 0
    private var lastTimestamp: TimeInterval = 0

    private let minimumStep: CGFloat = 10
    private let requiredReversals = 4
    private let requiredDistance: CGFloat = 150
    private let maximumWindow: TimeInterval = 0.95
    private let maximumGap: TimeInterval = 0.35

    func record(location: CGPoint, timestamp: TimeInterval) -> Bool {
        defer {
            lastPoint = location
            lastTimestamp = timestamp
        }

        guard let lastPoint else {
            reset(startingAt: location, timestamp: timestamp)
            return false
        }

        if timestamp - lastTimestamp > maximumGap {
            reset(startingAt: location, timestamp: timestamp)
            return false
        }

        let dx = location.x - lastPoint.x
        guard abs(dx) >= minimumStep else { return false }

        if windowStartTime == 0 {
            windowStartTime = timestamp
        }

        if timestamp - windowStartTime > maximumWindow {
            reset(startingAt: location, timestamp: timestamp)
            return false
        }

        let direction: CGFloat = dx > 0 ? 1 : -1
        totalHorizontalDistance += abs(dx)

        if lastDirection != 0, direction != lastDirection {
            reversalCount += 1
        }
        lastDirection = direction

        if reversalCount >= requiredReversals, totalHorizontalDistance >= requiredDistance {
            reset(startingAt: location, timestamp: timestamp)
            return true
        }

        return false
    }

    func reset() {
        lastPoint = nil
        lastDirection = 0
        reversalCount = 0
        totalHorizontalDistance = 0
        windowStartTime = 0
        lastTimestamp = 0
    }

    private func reset(startingAt location: CGPoint, timestamp: TimeInterval) {
        lastPoint = location
        lastDirection = 0
        reversalCount = 0
        totalHorizontalDistance = 0
        windowStartTime = timestamp
        lastTimestamp = timestamp
    }
}
