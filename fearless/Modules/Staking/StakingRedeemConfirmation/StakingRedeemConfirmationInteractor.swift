import UIKit
import SoraKeystore
import RobinHood
import BigInt
import SSFUtils
import IrohaCrypto
import SSFModels

final class StakingRedeemConfirmationInteractor: RuntimeConstantFetching, AccountFetching {
    weak var presenter: StakingRedeemConfirmationInteractorOutputProtocol!

    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let chainAsset: ChainAsset
    let wallet: MetaAccountModel
    let strategy: StakingRedeemConfirmationStrategy

    private var priceProvider: AnySingleValueProvider<[PriceData]>?

    init(
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        strategy: StakingRedeemConfirmationStrategy
    ) {
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.strategy = strategy
    }
}

extension StakingRedeemConfirmationInteractor: StakingRedeemConfirmationInteractorInputProtocol {
    func estimateFee(builderClosure: ExtrinsicBuilderClosure?, reuseIdentifier: String?) {
        strategy.estimateFee(builderClosure: builderClosure, reuseIdentifier: reuseIdentifier)
    }

    func submit(builderClosure: ExtrinsicBuilderClosure?) {
        strategy.submit(builderClosure: builderClosure)
    }

    func setup() {
        priceProvider = subscribeToPrice(for: chainAsset)

        strategy.setup()
    }
}

extension StakingRedeemConfirmationInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, chainAsset _: ChainAsset) {
        presenter.didReceivePriceData(result: result)
    }
}
