import Foundation
import FearlessUtils
import CommonWallet
import RobinHood
import SoraFoundation

struct WalletTransactionHistoryViewFactory {
    static func createView(asset: AssetModel, chain: ChainModel, selectedAccount: MetaAccountModel) -> WalletTransactionHistoryViewProtocol? {
        let txStorage: CoreDataRepository<TransactionHistoryItem, CDTransactionHistoryItem> =
            SubstrateDataStorageFacade.shared.createRepository()

        let operationFactory = HistoryOperationFactory(txStorage: AnyDataProviderRepository(txStorage))

        let dataProviderFactory = HistoryDataProviderFactory(cacheFacade: SubstrateDataStorageFacade.shared, operationFactory: operationFactory)
        let service = HistoryService(operationFactory: operationFactory, operationQueue: OperationQueue())

        let interactor = WalletTransactionHistoryInteractor(
            chain: chain,
            asset: asset,
            selectedAccount: selectedAccount,
            dataProviderFactory: dataProviderFactory,
            historyService: service,
            logger: Logger.shared,
            defaultFilter: WalletHistoryRequest(assets: [asset.identifier]),
            selectedFilter: WalletHistoryRequest(assets: [asset.identifier]),
            filters: transactionHistoryFilters()
        )
        let wireframe = WalletTransactionHistoryWireframe()

        let viewModelFactory = WalletTransactionHistoryViewModelFactory(
            balanceFormatterFactory: AssetBalanceFormatterFactory(),
            includesFeeInAmount: true,
            transactionTypes: [.incoming, .outgoing],
            asset: asset,
            iconGenerator: PolkadotIconGenerator()
        )

        let presenter = WalletTransactionHistoryPresenter(
            interactor: interactor,
            wireframe: wireframe,
            viewModelFactory: viewModelFactory,
            chain: chain,
            asset: asset,
            localizationManager: LocalizationManager.shared
        )

        let view = WalletTransactionHistoryViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }

    static func transactionHistoryFilters() -> [FilterSet] {
        [FilterSet(
            title: R.string.localizable.walletFiltersHeader(preferredLanguages: LocalizationManager.shared.selectedLocale.rLanguages),
            items: [WalletTransactionHistoryFilter(type: .transfer, selected: true),
                    WalletTransactionHistoryFilter(type: .reward, selected: true),
                    WalletTransactionHistoryFilter(type: .other, selected: true)]
        )]
    }
}