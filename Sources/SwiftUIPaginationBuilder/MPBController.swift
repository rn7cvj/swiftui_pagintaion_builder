import Foundation
import Combine

public typealias MPBDataLoader<Item: Identifiable> = (
    _ pageIndex: Int,
    _ pageSize: Int,
    _ filters: [String: Any]?
) async throws -> [Item]

@MainActor
public final class MPBController<Item: Identifiable>: ObservableObject {
    @Published public private(set) var state: MPBControllerState<Item>

    public let dataLoader: MPBDataLoader<Item>
    public let initialPageIndex: Int
    public let pageSize: Int

    private var isLoading = false
    private var internalFilters: [String: Any]?

    public var filters: [String: Any]? {
        internalFilters
    }

    public init(
        dataLoader: @escaping MPBDataLoader<Item>,
        initialPageIndex: Int = 0,
        pageSize: Int = 128,
        filters: [String: Any]? = nil,
        autoLoadFirstPage: Bool = true
    ) {
        self.dataLoader = dataLoader
        self.initialPageIndex = initialPageIndex
        self.pageSize = pageSize
        self.internalFilters = filters
        self.state = MPBControllerState(
            items: [],
            currentPage: initialPageIndex - 1
        )

        if autoLoadFirstPage {
            Task { [weak self] in
                await self?.loadNextPage()
            }
        }
    }

    public func loadNextPage() async {
        if isLoading || state.isLastPage {
            return
        }

        isLoading = true
        let nextPage = state.currentPage + 1

        do {
            let newItems = try await dataLoader(nextPage, pageSize, internalFilters)
            state = MPBControllerState(
                items: state.items + newItems,
                isFirstPage: false,
                currentPage: nextPage,
                isLastPage: newItems.count != pageSize
            )
        } catch {
            // Matches original behavior: errors are swallowed.
        }

        isLoading = false
    }

    // API compatibility with the original Dart package naming.
    public func loadNexPage() async {
        await loadNextPage()
    }

    public func refresh() async {
        await refresh(silent: true)
    }

    /// Refreshes data from the first page.
    /// - Parameter silent: When `true`, keeps current items visible until fresh data arrives.
    ///   This mode is recommended for `.refreshable` to avoid scroll/header glitches.
    public func refresh(silent: Bool) async {
        if silent {
            await refreshSilently()
            return
        }

        isLoading = false
        state = MPBControllerState(items: [], currentPage: initialPageIndex - 1)
        await loadNextPage()
    }

    public func reset(newFilters: [String: Any]? = nil) async {
        internalFilters = newFilters
        isLoading = false
        state = MPBControllerState(items: [], currentPage: initialPageIndex - 1)
        await loadNextPage()
    }

    public func updateFilters(_ newFilters: [String: Any]?) {
        internalFilters = newFilters
    }

    @discardableResult
    public func updateById(_ item: Item) -> Bool {
        guard let index = state.items.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        var updatedItems = state.items
        updatedItems[index] = item
        state.items = updatedItems
        return true
    }

    @discardableResult
    public func deleteById(_ id: Item.ID) -> Bool {
        let updatedItems = state.items.filter { $0.id != id }
        guard updatedItems.count != state.items.count else {
            return false
        }

        state.items = updatedItems
        return true
    }

    @discardableResult
    public func insert(_ index: Int, item: Item) -> Bool {
        guard index >= 0 && index <= state.items.count else {
            return false
        }

        var updatedItems = state.items
        updatedItems.insert(item, at: index)
        state.items = updatedItems
        return true
    }

    public func addFirst(_ item: Item) {
        _ = insert(0, item: item)
    }

    public func addLast(_ item: Item) {
        _ = insert(state.items.count, item: item)
    }

    private func refreshSilently() async {
        if isLoading {
            return
        }

        isLoading = true

        do {
            let firstPageItems = try await dataLoader(initialPageIndex, pageSize, internalFilters)
            state = MPBControllerState(
                items: firstPageItems,
                isFirstPage: false,
                currentPage: initialPageIndex,
                isLastPage: firstPageItems.count != pageSize
            )
        } catch {
            // Matches original behavior: errors are swallowed.
        }

        isLoading = false
    }
}
