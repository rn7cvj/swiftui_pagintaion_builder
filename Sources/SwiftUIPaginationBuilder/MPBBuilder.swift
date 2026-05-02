import SwiftUI

public struct MPBBuilder<
    Item: Identifiable,
    ItemContent: View,
    FirstLoadingContent: View,
    EmptyContent: View
>: View {
    @ObservedObject private var controller: MPBController<Item>

    private let itemBuilder: (_ item: Item, _ index: Int, _ isFirst: Bool, _ isLast: Bool) -> ItemContent
    private let firstLoadingBuilder: () -> FirstLoadingContent
    private let noItemBuilder: () -> EmptyContent

    private let spacing: CGFloat
    private let padding: EdgeInsets
    private let loadMoreOffset: CGFloat
    private let reversed: Bool
    private let refresh: (() async -> Void)?

    public init(
        controller: MPBController<Item>,
        spacing: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(),
        loadMoreOffset: CGFloat = 256,
        reversed: Bool = false,
        refresh: (() async -> Void)? = nil,
        @ViewBuilder itemBuilder: @escaping (_ item: Item, _ index: Int, _ isFirst: Bool, _ isLast: Bool) -> ItemContent,
        @ViewBuilder firstLoadingBuilder: @escaping () -> FirstLoadingContent,
        @ViewBuilder noItemBuilder: @escaping () -> EmptyContent
    ) {
        self.controller = controller
        self.spacing = spacing
        self.padding = padding
        self.loadMoreOffset = loadMoreOffset
        self.reversed = reversed
        self.refresh = refresh
        self.itemBuilder = itemBuilder
        self.firstLoadingBuilder = firstLoadingBuilder
        self.noItemBuilder = noItemBuilder
    }

    private var renderedItems: [Item] {
        reversed ? Array(controller.state.items.reversed()) : controller.state.items
    }

    public var body: some View {
        Group {
            if !controller.state.isFirstPage && !controller.state.items.isEmpty {
                if let refresh {
                    contentScrollView()
                        .refreshable {
                            await refresh()
                        }
                } else {
                    contentScrollView()
                }
            } else if controller.state.isFirstPage {
                firstLoadingBuilder()
            } else {
                noItemBuilder()
            }
        }
    }

    private func contentScrollView() -> some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(Array(renderedItems.enumerated()), id: \.element.id) { index, item in
                    itemBuilder(
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
