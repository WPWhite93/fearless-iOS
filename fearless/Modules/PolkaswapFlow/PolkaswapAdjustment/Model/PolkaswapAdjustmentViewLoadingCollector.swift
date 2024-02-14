import Foundation

struct PolkaswapAdjustmentViewLoadingCollector {
    var feeReady: Bool = false
    var fromReady: Bool = false
    var toReady: Bool = false
    var detailsReady: Bool = false

    mutating func reset() {
        feeReady = false
        fromReady = false
        toReady = false
        detailsReady = false
    }

    var isReady: Bool {
        feeReady && fromReady && toReady && detailsReady
    }
}
