import SwiftUI

struct QuickAccessStackView: View {
    @ObservedObject var manager: QuickAccessManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: QuickAccessLayout.cardSpacing) {
            if manager.position.isTopEdge {
                positionedCards
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                positionedCards
            }
        }
        .padding(QuickAccessLayout.containerPadding)
        .frame(
            width: panelSize.width,
            height: panelSize.height
        )
    }

    private var panelSize: CGSize {
        QuickAccessLayout.fixedPanelSize(includesDropPlaceholder: manager.isDropPlaceholderVisible)
    }

    @ViewBuilder
    private var positionedCards: some View {
        if manager.position.isTopEdge {
            if manager.isDropPlaceholderVisible {
                QuickAccessDropZoneCardView(manager: manager)
                    .transition(cardTransition)
            }

            ForEach(floatingItemsInVisualOrder) { item in
                cardView(for: item)
            }

            if manager.hasOverflowCard {
                QuickAccessOverflowCardView(summary: overflowSummary, reduceMotion: reduceMotion)
                    .equatable()
                    .transition(cardTransition)
            }
        } else {
            if manager.hasOverflowCard {
                QuickAccessOverflowCardView(summary: overflowSummary, reduceMotion: reduceMotion)
                    .equatable()
                    .transition(cardTransition)
            }

            ForEach(floatingItemsInVisualOrder) { item in
                cardView(for: item)
            }

            if manager.isDropPlaceholderVisible {
                QuickAccessDropZoneCardView(manager: manager)
                    .transition(cardTransition)
            }
        }
    }

    private func cardView(for item: QuickAccessItem) -> some View {
        QuickAccessCardView(
            item: item,
            position: manager.position,
            onRemove: { id in manager.removeItem(id: id) },
            onOpen: { id in manager.openItem(for: id) },
            onReveal: { id in manager.revealOutput(for: id) },
            onConvert: { id, target in manager.convertItem(id: id, to: target) },
            reduceMotion: reduceMotion
        )
        .equatable()
        .transition(cardTransition)
    }

    private var cardTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: transitionEdge)
                .combined(with: .opacity),
            removal: .move(edge: transitionEdge)
                .combined(with: .opacity)
        )
    }

    private var transitionEdge: Edge {
        if manager.position.isTopEdge {
            return .top
        }

        switch manager.position.alignment {
        case .left:
            return .leading
        case .center:
            return .bottom
        case .right:
            return .trailing
        }
    }

    private var floatingItemsInVisualOrder: [QuickAccessItem] {
        if manager.position.isTopEdge {
            return manager.floatingItems
        }
        return Array(manager.floatingItems.reversed())
    }

    private var overflowSummary: QuickAccessOverflowSummary {
        QuickAccessOverflowSummary(
            hiddenCount: manager.hiddenFloatingItemCount,
            processingCount: manager.processingCount,
            queuedCount: manager.queuedCount,
            completedCount: manager.completedCount,
            failedCount: manager.failedCount
        )
    }
}

private struct QuickAccessOverflowSummary: Equatable {
    let hiddenCount: Int
    let processingCount: Int
    let queuedCount: Int
    let completedCount: Int
    let failedCount: Int
}

private struct QuickAccessOverflowCardView: View, Equatable {
    let summary: QuickAccessOverflowSummary
    let reduceMotion: Bool
    @State private var isHovering = false

    static func == (lhs: QuickAccessOverflowCardView, rhs: QuickAccessOverflowCardView) -> Bool {
        lhs.summary == rhs.summary
            && lhs.reduceMotion == rhs.reduceMotion
    }

    var body: some View {
        ZStack {
            background
            readabilityOverlay

            VStack(spacing: 0) {
                topBadge
                Spacer(minLength: 0)
                summaryContent
            }
        }
        .frame(width: QuickAccessLayout.cardWidth, height: QuickAccessLayout.overflowCardHeight)
        .clipShape(cardShape)
        .overlay(cardShape.strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .compositingGroup()
        .quickAccessCardShadow(isRaised: isHovering)
        .scaleEffect(isHovering && !reduceMotion ? 1.008 : 1)
        .onHover { hovering in
            withAnimation(QuickAccessAnimations.hoverOverlay) {
                isHovering = hovering
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .black.opacity(0.80),
                    .black.opacity(0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(.white.opacity(Double(3 - index) * 0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(
                        width: QuickAccessLayout.cardWidth - CGFloat(index * 18) - 26,
                        height: 28
                    )
                    .offset(x: CGFloat(index * 7), y: CGFloat(index * 10) - 18)
                    .rotationEffect(.degrees(Double(index - 1) * 2.4))
            }
        }
        .frame(width: QuickAccessLayout.cardWidth, height: QuickAccessLayout.overflowCardHeight)
        .clipped()
        .overlay(Color.black.opacity(0.22))
    }

    private var readabilityOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.08),
                .clear,
                .black.opacity(0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBadge: some View {
        HStack(alignment: .top) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 20)
                .droplitMaterialBackground(.regular, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.white.opacity(0.20), lineWidth: 1)
                )

            Spacer()

            Text("+\(summary.hiddenCount)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .droplitMonospacedDigit()
                .frame(minWidth: 28)
                .frame(height: 20)
                .padding(.horizontal, 4)
                .droplitMaterialBackground(.regular, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.20), lineWidth: 1))
        }
        .padding(.horizontal, 7)
        .padding(.top, 7)
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(summary.hiddenCount) hidden")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.82))
                .lineLimit(1)

            Text("Stacked items")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(summaryText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.bottom, 9)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: QuickAccessLayout.cornerRadius, style: .continuous)
    }

    private var summaryText: String {
        let parts = [
            labeledCount(summary.processingCount, "processing"),
            labeledCount(summary.queuedCount, "queued"),
            labeledCount(summary.completedCount, "done"),
            labeledCount(summary.failedCount, "failed")
        ].compactMap { $0 }
        return parts.isEmpty ? "Queue active" : parts.joined(separator: " · ")
    }

    private func labeledCount(_ count: Int, _ label: String) -> String? {
        count > 0 ? "\(count) \(label)" : nil
    }
}
