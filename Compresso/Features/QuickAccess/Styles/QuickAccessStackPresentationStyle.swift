import SwiftUI

nonisolated struct QuickAccessStackPresentationStyle {
    func metrics(for context: QuickAccessPresentationContext) -> QuickAccessPresentationMetrics {
        let visibleItems = stackItems(in: context)
        let hiddenCount = max(context.items.count - visibleItems.count, 0)
        let visibleElementCount = visibleItems.count
            + (context.isDropPlaceholderVisible ? 1 : 0)
            + (hiddenCount > 0 ? 1 : 0)

        guard visibleElementCount > 0 else { return .empty }

        let panelSize = QuickAccessLayout.fixedStackPanelSize(
            includesDropPlaceholder: context.isDropPlaceholderVisible
        )
        let contentSize = QuickAccessLayout.stackPanelSize(
            itemCardCount: visibleItems.count,
            conversionActionRowCount: visibleItems.filter(\.hasConversionTargets).count,
            dropPlaceholderCount: context.isDropPlaceholderVisible ? 1 : 0,
            includesOverflowCard: hiddenCount > 0
        )

        return QuickAccessPresentationMetrics(
            panelSize: panelSize,
            activeContentHeight: min(contentSize.height, panelSize.height),
            visibleElementCount: visibleElementCount,
            shadowMargin: QuickAccessLayout.shadowMargin
        )
    }

    func stackItems(in context: QuickAccessPresentationContext) -> [QuickAccessItem] {
        Array(context.items.prefix(QuickAccessLayout.stackMaximumItems))
    }
}
