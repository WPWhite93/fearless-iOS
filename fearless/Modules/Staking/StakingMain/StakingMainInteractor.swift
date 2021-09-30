import Foundation
import SoraKeystore
import RobinHood
import FearlessUtils
import SoraFoundation

final class StakingMainInteractor: RuntimeConstantFetching {
    weak var presenter: StakingMainInteractorOutputProtocol!

    let selectedWalletSettings: SelectedWalletSettings
    let chainRegistry: ChainRegistryProtocol
    let stakingRemoteSubscriptionService: StakingRemoteSubscriptionServiceProtocol
    let stakingLocalSubscriptionFactory: StakingLocalSubscriptionFactoryProtocol
    let walletLocalSubscriptionFactory: WalletLocalSubscriptionFactoryProtocol
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let stakingServiceFactory: StakingServiceFactoryProtocol
    let accountProviderFactory: AccountProviderFactoryProtocol
    let eventCenter: EventCenterProtocol
    let operationManager: OperationManagerProtocol
    let eraInfoOperationFactory: NetworkStakingInfoOperationFactoryProtocol
    let applicationHandler: ApplicationHandlerProtocol
    let eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol
    let commonSettings: SettingsManagerProtocol
    let logger: LoggerProtocol?

    var selectedAccount: ChainAccountResponse?
    var selectedChainAsset: ChainAsset?

    private(set) var stakingSettings: StakingAssetSettings
    private(set) var stakingSharedState: StakingSharedState?

    var priceProvider: AnySingleValueProvider<PriceData>?
    var balanceProvider: AnyDataProvider<DecodedAccountInfo>?
    var stashControllerProvider: StreamableProvider<StashItem>?
    var validatorProvider: AnyDataProvider<DecodedValidator>?
    var nominatorProvider: AnyDataProvider<DecodedNomination>?
    var ledgerProvider: AnyDataProvider<DecodedLedgerInfo>?
    var totalRewardProvider: AnySingleValueProvider<TotalRewardItem>?
    var payeeProvider: AnyDataProvider<DecodedPayee>?
    var controllerAccountProvider: StreamableProvider<AccountItem>?
    var minNominatorBondProvider: AnyDataProvider<DecodedBigUInt>?
    var counterForNominatorsProvider: AnyDataProvider<DecodedU32>?
    var maxNominatorsCountProvider: AnyDataProvider<DecodedU32>?

    let analyticsPeriod = AnalyticsPeriod.week

    init(
        selectedWalletSettings: SelectedWalletSettings,
        stakingSettings: StakingAssetSettings,
        chainRegistry: ChainRegistryProtocol,
        stakingRemoteSubscriptionService: StakingRemoteSubscriptionServiceProtocol,
        stakingLocalSubscriptionFactory: StakingLocalSubscriptionFactoryProtocol,
        walletLocalSubscriptionFactory: WalletLocalSubscriptionFactoryProtocol,
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        stakingServiceFactory: StakingServiceFactoryProtocol,
        accountProviderFactory: AccountProviderFactoryProtocol,
        eventCenter: EventCenterProtocol,
        operationManager: OperationManagerProtocol,
        eraInfoOperationFactory: NetworkStakingInfoOperationFactoryProtocol,
        applicationHandler: ApplicationHandlerProtocol,
        eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol,
        commonSettings: SettingsManagerProtocol,
        logger: LoggerProtocol?
    ) {
        self.selectedWalletSettings = selectedWalletSettings
        self.stakingSettings = stakingSettings
        self.chainRegistry = chainRegistry
        self.stakingRemoteSubscriptionService = stakingRemoteSubscriptionService
        self.stakingLocalSubscriptionFactory = stakingLocalSubscriptionFactory
        self.walletLocalSubscriptionFactory = walletLocalSubscriptionFactory
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.stakingServiceFactory = stakingServiceFactory
        self.accountProviderFactory = accountProviderFactory
        self.eventCenter = eventCenter
        self.operationManager = operationManager
        self.eraInfoOperationFactory = eraInfoOperationFactory
        self.applicationHandler = applicationHandler
        self.eraCountdownOperationFactory = eraCountdownOperationFactory
        self.commonSettings = commonSettings
        self.logger = logger
    }

    func setupSelectedAccountAndChainAsset() {
        guard
            let wallet = selectedWalletSettings.value,
            let chainAsset = stakingSettings.value,
            let response = wallet.fetch(for: chainAsset.chain.accountRequest()) else {
            return
        }

        selectedAccount = response
        selectedChainAsset = chainAsset
    }

    func setupSharedState() {
        guard let chainAsset = selectedChainAsset else {
            return
        }

        do {
            let eraValidatorService = try stakingServiceFactory.createEraValidatorService(
                for: chainAsset.chain.chainId
            )

            let rewardCalculatorService = try stakingServiceFactory.createRewardCalculatorService(
                for: chainAsset.chain.chainId,
                assetPrecision: Int16(chainAsset.asset.precision),
                validatorService: eraValidatorService
            )

            stakingSharedState = StakingSharedState(
                settings: stakingSettings,
                eraValidatorService: eraValidatorService,
                rewardCalculationService: rewardCalculatorService,
                stakingLocalSubscriptionFactory: stakingLocalSubscriptionFactory
            )
        } catch {
            logger?.error("Couldn't create shared state")
        }
    }

    func provideSelectedAccount() {
        guard let address = selectedAccount?.toAddress() else {
            return
        }

        presenter.didReceive(selectedAddress: address)
    }

    func provideMaxNominatorsPerValidator(from runtimeService: RuntimeCodingServiceProtocol) {
        fetchConstant(
            for: .maxNominatorRewardedPerValidator,
            runtimeCodingService: runtimeService,
            operationManager: operationManager
        ) { [weak self] result in
            self?.presenter.didReceiveMaxNominatorsPerValidator(result: result)
        }
    }

    func provideNewChain() {
        guard let chainAsset = selectedChainAsset else {
            return
        }

        presenter.didReceive(newChainAsset: chainAsset)
    }

    func provideRewardCalculator(from calculatorService: RewardCalculatorServiceProtocol) {
        let operation = calculatorService.fetchCalculatorOperation()

        operation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                do {
                    let engine = try operation.extractNoCancellableResultData()
                    self?.presenter.didReceive(calculator: engine)
                } catch {
                    self?.presenter.didReceive(calculatorError: error)
                }
            }
        }

        operationManager.enqueue(operations: [operation], in: .transient)
    }

    func provideEraStakersInfo(from eraValidatorService: EraValidatorServiceProtocol) {
        let operation = eraValidatorService.fetchInfoOperation()

        operation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                do {
                    let info = try operation.extractNoCancellableResultData()
                    self?.presenter.didReceive(eraStakersInfo: info)
                    self?.fetchEraCompletionTime()
                } catch {
                    self?.presenter.didReceive(calculatorError: error)
                }
            }
        }

        operationManager.enqueue(operations: [operation], in: .transient)
    }

    func provideNetworkStakingInfo() {
        let wrapper = eraInfoOperationFactory.networkStakingOperation()

        wrapper.targetOperation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                do {
                    let info = try wrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceive(networkStakingInfo: info)
                } catch {
                    self?.presenter.didReceive(networkStakingInfoError: error)
                }
            }
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)
    }

    func fetchEraCompletionTime() {
        let operationWrapper = eraCountdownOperationFactory.fetchCountdownOperationWrapper()
        operationWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let result = try operationWrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceive(eraCountdownResult: .success(result))
                } catch {
                    self?.presenter.didReceive(eraCountdownResult: .failure(error))
                }
            }
        }
        operationManager.enqueue(operations: operationWrapper.allOperations, in: .transient)
    }
}
