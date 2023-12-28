import RobinHood
import IrohaCrypto
import BigInt
import SoraKeystore
import SSFUtils
import SSFModels

final class StakingBondMoreConfirmationInteractor: AccountFetching {
    weak var presenter: StakingBondMoreConfirmationOutputProtocol!

    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol

    private let chainAsset: ChainAsset
    private let wallet: MetaAccountModel
    private let strategy: StakingBondMoreConfirmationStrategy

    private var priceProvider: AnySingleValueProvider<[PriceData]>?

    init(
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        strategy: StakingBondMoreConfirmationStrategy
    ) {
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.strategy = strategy
    }
}

extension StakingBondMoreConfirmationInteractor: StakingBondMoreConfirmationInteractorInputProtocol {
    func setup() {
        priceProvider = subscribeToPrice(for: chainAsset)

        strategy.setup()
    }

    func estimateFee(builderClosure: ExtrinsicBuilderClosure?, reuseIdentifier: String?) {
        strategy.estimateFee(builderClosure: builderClosure, reuseIdentifier: reuseIdentifier)
    }

    func submit(builderClosure: ExtrinsicBuilderClosure?) {
        strategy.submit(builderClosure: builderClosure)
    }
}

extension StakingBondMoreConfirmationInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, chainAsset _: ChainAsset) {
        presenter.didReceivePriceData(result: result)
    }
}
