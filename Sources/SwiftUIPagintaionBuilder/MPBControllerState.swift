import Foundation

public struct MPBControllerState<Item: Identifiable> {
    public var items: [Item]
    public var isFirstPage: Bool
    public var currentPage: Int
    public var isLastPage: Bool

    public init(
        items: [Item],
        isFirstPage: Bool = true,
        currentPage: Int = 0,
        isLastPage: Bool = false
    ) {
        self.items = items
        self.isFirstPage = isFirstPage
        self.currentPage = currentPage
        self.isLastPage = isLastPage
    }
}

public typealias MBDControllerState<Item: Identifiable> = MPBControllerState<Item>
