import SwiftUI

struct QuickAccessBoxEmptyStateView: View {
    let isTargeted: Bool
    let hasPendingDropSummary: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(isTargeted ? 0.18 : 0.10), lineWidth: 1)
                    .frame(width: 46, height: 46)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(isTargeted ? 0.64 : 0.42))
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(isTargeted ? 0.68 : 0.52))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.32))
                    .lineLimit(1)
            }
        }
        .frame(width: 118, height: 96)
        .scaleEffect(isTargeted ? 1.04 : 1)
    }

    private var iconName: String {
        isTargeted ? "tray.full" : "tray.and.arrow.down"
    }

    private var title: String {
        isTargeted ? "Release to Drop" : "Drop Items"
    }

    private var subtitle: String {
        hasPendingDropSummary ? "Ready to optimize" : "Waiting for media"
    }
}
