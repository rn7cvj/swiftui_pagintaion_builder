import SwiftUI

public struct MPBBuilder<
    Item: MPBIdentifiable,
    ItemContent: View,
    FirstLoadingContent: View,
    EmptyContent: View
>: View {
    @ObservedObject private var controller: MPBController<Item>

    private let itemBuilder: (_ width: CGFloat, _ item: Item, _ index: Int, _ isFirst: Bool, _ isLast: Bool) -> ItemContent
    private let firstLoadingBuilder: (_ width: CGFloat) -> FirstLoadingContent
    private let noItemBuilder: (_ width: CGFloat) -> EmptyContent

    private let spacing: CGFloat
    private let padding: EdgeInsets
    private let loadMoreOffset: CGFloat
    private let reversed: Bool

    public init(
        controller: MPBController<Item>,
        spacing: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(),
        loadMoreOffset: CGFloat = 256,
        reversed: Bool = false,
        @ViewBuilder itemBuilder: @escaping (_ width: CGFloat, _ item: Item, _ index: Int, _ isFirst: Bool, _ isLast: Bool) -> ItemContent,
        @ViewBuilder firstLoadingBuilder: @escaping (_ width: CGFloat) -> FirstLoadingContent,
        @ViewBuilder noItemBuilder: @escaping (_ width: CGFloat) -> EmptyContent
    ) {
        self.controller = controller
        self.spacing = spacing
        self.padding = padding
        self.loadMoreOffset = loadMoreOffset
        self.reversed = reversed
        self.itemBuilder = itemBuilder
        self.firstLoadingBuilder = firstLoadingBuilder
        self.noItemBuilder = noItemBuilder
    }

    private var renderedItems: [Item] {
        reversed ? Array(controller.state.items.reversed()) : controller.state.items
    }

    public var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - padding.leading - padding.trailing)

            Group {
                if !controller.state.isFirstPage && !controller.state.items.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: spacing) {
                            ForEach(Array(renderedItems.enumerated()), id: \.element.mpbId) { index, item in
                                itemBuilder(
                                    contentWidth,
                                    item,
                                    index,
                                    index == 0,
                                    index == renderedItems.count - 1
                                )
                                .onAppear {
                                    if shouldLoadMore(index: index, count: renderedItems.count) {
                                        Task {
                                            await controller.loadNextPage()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(padding)
                    }
                } else if controller.state.isFirstPage {
                    firstLoadingBuilder(contentWidth)
                } else {
                    noItemBuilder(contentWidth)
                }
            }
        }
    }

    private func shouldLoadMore(index: Int, count: Int) -> Bool {
        guard count > 0 else {
            return false
        }

        let estimatedItemHeight: CGFloat = 88
        let prefetchCount = max(1, Int(loadMoreOffset / estimatedItemHeight))

        if reversed {
            return index <= prefetchCount - 1
        }

        return index >= count - prefetchCount
    }
}
