// From Snap
import Foundation
import SwiftUI

struct SnapPointCalculator<State: SnapState> {
    struct SnapResult {
        let state: State
        let offset: CGFloat
        let contentHeight: CGFloat

        static var zero: SnapResult {
            SnapResult(state: .invisibleState, offset: UIScreen.main.bounds.height, contentHeight: 0)
        }
    }

    struct SnapRange {
        let upper: SnapResult
        let lower: SnapResult

        var offsetRange: ClosedRange<CGFloat> {
            upper.offset ... lower.offset
        }
    }

    let ranges: [SnapRange]
    let results: [SnapResult]

    init(results: [SnapResult]) {
        assert(!results.isEmpty, "Invalid Empty Calculation")

        let ranges = results.pairs().map { SnapRange(upper: $0, lower: $1) }
        assert(ranges.allSatisfy { $0.upper.offset < $0.lower.offset }, "Ranges are invalid")
        self.ranges = ranges
        self.results = results
    }

    func callAsFunction(state: State) -> SnapResult {
        results.first { $0.state == state } ?? .zero
    }

    func callAsFunction(current: SnapResult, drag: DragGesture.Value) -> SnapResult {
        // TODO: this still has some work todo
        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
        let cardTopEdgeLocation = current.offset + drag.translation.height

        let matchingRanges = ranges.filter { $0.offsetRange.contains(cardTopEdgeLocation) }
        guard let range = drag.translation.height > 0 ? matchingRanges.last : matchingRanges.first else {
            if drag.translation.height < 0 {
                return results.first!
            } else {
                return results.last!
            }
        }

        if verticalDirection > 0 {
            return range.lower
        } else if verticalDirection < 0 {
            return range.upper
        } else if (cardTopEdgeLocation - range.upper.offset) < (range.lower.offset - cardTopEdgeLocation) {
            return range.upper
        } else {
            return range.lower
        }
    }
}

extension SnapPointCalculator {
    struct Input {
        let state: State
        let point: SnapPoint
    }

    init(snaps: [Input], height: CGFloat) {
        let deviceHeight: CGFloat = max(CGFloat(snaps.count), height)

        let results = snaps.map { input -> SnapResult in
            let offset = input.point.offset(deviceHeight: deviceHeight, safeAreaInsets: .zero)
            return SnapResult(state: input.state,
                              offset: offset,
                              contentHeight: deviceHeight - offset)
        }

        self.init(results: results)
    }
}

private extension SnapPoint {
    func offset(deviceHeight: CGFloat, safeAreaInsets: UIEdgeInsets) -> CGFloat {
        switch self {
        case let .fraction(fraction):
            return deviceHeight * (1 - fraction)
        case let .height(height):
            let totalHeight = height + safeAreaInsets.top + safeAreaInsets.bottom + handleThickness + 3 * handleVerticalPadding
            return deviceHeight - totalHeight
        case let .paddingToTop(offset):
            return offset
        }
    }
}

extension Collection {
    func pairs() -> AnySequence<(Element, Element)> {
        AnySequence(zip(self, dropFirst()))
    }
}
