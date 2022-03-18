import UIKit
import RobinHood
import BigInt
import FearlessUtils

final class ChainAccountInteractor {
    weak var presenter: ChainAccountInteractorOutputProtocol?
    private let selectedMetaAccount: MetaAccountModel
    var chain: ChainModel
    private let asset: AssetModel
    private let runtimeService: RuntimeCodingServiceProtocol
    private let operationManager: OperationManagerProtocol
    let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let storageRequestFactory: StorageRequestFactoryProtocol
    let connection: JSONRPCEngine
    let eventCenter: EventCenterProtocol
    let transactionSubscription: StorageSubscriptionContainer?
    let repository: AnyDataProviderRepository<MetaAccountModel>
    let availableExportOptionsProvider: AvailableExportOptionsProviderProtocol

    var accountInfoProvider: AnyDataProvider<DecodedAccountInfo>?

    init(
        selectedMetaAccount: MetaAccountModel,
        chain: ChainModel,
        asset: AssetModel,
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol,
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        storageRequestFactory: StorageRequestFactoryProtocol,
        connection: JSONRPCEngine,
        operationManager: OperationManagerProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        eventCenter: EventCenterProtocol,
        transactionSubscription: StorageSubscriptionContainer?,
        repository: AnyDataProviderRepository<MetaAccountModel>,
        availableExportOptionsProvider: AvailableExportOptionsProviderProtocol
    ) {
        self.selectedMetaAccount = selectedMetaAccount
        self.chain = chain
        self.asset = asset
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.connection = connection
        self.storageRequestFactory = storageRequestFactory
        self.runtimeService = runtimeService
        self.operationManager = operationManager
        self.eventCenter = eventCenter
        self.transactionSubscription = transactionSubscription
        self.repository = repository
        self.availableExportOptionsProvider = availableExportOptionsProvider
    }

    private func subscribeToAccountInfo() {
        if let accountId = selectedMetaAccount.fetch(for: chain.accountRequest())?.accountId {
            accountInfoSubscriptionAdapter.subscribe(chain: chain, accountId: accountId, handler: self)
        } else {
            presenter?.didReceiveAccountInfo(
                result: .failure(ChainAccountFetchingError.accountNotExists),
                for: chain.chainId
            )
        }
    }

    private func fetchBalanceLocks() {
        if let accountId = selectedMetaAccount.fetch(for: chain.accountRequest())?.accountId {
            let balanceLocksOperation = createBalanceLocksFetchOperation(accountId)
            balanceLocksOperation.targetOperation.completionBlock = { [weak self] in
                DispatchQueue.main.async {
                    do {
                        let balanceLocks = try balanceLocksOperation.targetOperation.extractNoCancellableResultData()
                        self?.presenter?.didReceiveBalanceLocks(result: .success(balanceLocks))
                    } catch {
                        self?.presenter?.didReceiveBalanceLocks(result: .failure(error))
                    }
                }
            }
            operationManager.enqueue(
                operations: balanceLocksOperation.allOperations,
                in: .transient
            )
        }
    }

    private func createBalanceLocksFetchOperation(_ accountId: AccountId) -> CompoundOperationWrapper<BalanceLocks?> {
        let coderFactoryOperation = runtimeService.fetchCoderFactoryOperation()

        let wrapper: CompoundOperationWrapper<[StorageResponse<BalanceLocks>]> = storageRequestFactory.queryItems(
            engine: connection,
            keyParams: { [accountId] },
            factory: { try coderFactoryOperation.extractNoCancellableResultData() },
            storagePath: .balanceLocks
        )

        let mapOperation = ClosureOperation<BalanceLocks?> {
            try wrapper.targetOperation.extractNoCancellableResultData().first?.value
        }

        wrapper.allOperations.forEach { $0.addDependency(coderFactoryOperation) }

        let dependencies = [coderFactoryOperation] + wrapper.allOperations

        dependencies.forEach { mapOperation.addDependency($0) }

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }
}

extension ChainAccountInteractor: ChainAccountInteractorInputProtocol {
    func setup() {
        eventCenter.add(observer: self)

        subscribeToAccountInfo()
        fetchMinimalBalance()
        fetchBalanceLocks()

        if let priceId = asset.priceId {
            _ = subscribeToPrice(for: priceId)
        }
    }

    func getAvailableExportOptions(for address: String) {
        fetchChainAccount(
            chain: chain,
            address: address,
            from: repository,
            operationManager: operationManager
        ) { [weak self] result in
            switch result {
            case let .success(chainResponse):
                guard let self = self, let response = chainResponse else {
                    self?.presenter?.didReceiveExportOptions(options: [.keystore])
                    return
                }
                let accountId = response.isChainAccount ? response.accountId : nil
                let options = self.availableExportOptionsProvider
                    .getAvailableExportOptions(
                        for: self.selectedMetaAccount.metaId,
                        accountId: accountId
                    )
                self.presenter?.didReceiveExportOptions(options: options)
            default:
                self?.presenter?.didReceiveExportOptions(options: [.keystore])
            }
        }
    }
}

extension ChainAccountInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, priceId: AssetModel.PriceId) {
        presenter?.didReceivePriceData(result: result, for: priceId)
    }
}

extension ChainAccountInteractor: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(
        result: Result<AccountInfo?, Error>,
        accountId _: AccountId,
        chainId: ChainModel.Id
    ) {
        presenter?.didReceiveAccountInfo(result: result, for: chainId)
    }
}

extension ChainAccountInteractor: RuntimeConstantFetching {
    func fetchMinimalBalance() {
        fetchConstant(
            for: .existentialDeposit,
            runtimeCodingService: runtimeService,
            operationManager: operationManager
        ) { [weak self] (result: Result<BigUInt, Error>) in
            self?.presenter?.didReceiveMinimumBalance(result: result)
        }
    }
}

extension ChainAccountInteractor: AnyProviderAutoCleaning {}

extension ChainAccountInteractor: EventVisitorProtocol {
    func processChainsUpdated(event: ChainsUpdatedEvent) {
        if let updated = event.updatedChains.first(where: { [weak self] updatedChain in
            guard let self = self else { return false }
            return updatedChain.chainId == self.chain.chainId
        }) {
            chain = updated
        }
    }

    func processSelectedConnectionChanged(event _: SelectedConnectionChanged) {
        accountInfoSubscriptionAdapter.reset()
        subscribeToAccountInfo()
    }
}

extension ChainAccountInteractor: AccountFetching {}
