import UIKit
import SoraFoundation
import SSFModels
import RobinHood
import SoraKeystore
import SSFStorageQueryKit

final class AssetManagementAssembly {
    static func configureModule(
        networkFilter: NetworkManagmentFilter?,
        wallet: MetaAccountModel
    ) -> AssetManagementModuleCreationResult? {
        let localizationManager = LocalizationManager.shared

        let priceLocalSubscriber = PriceLocalStorageSubscriberImpl.shared
        let chainRepository = ChainRepositoryFactory().createRepository()
        let chainAssetFetching = ChainAssetsFetching(
            chainRepository: AnyDataProviderRepository(chainRepository),
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let substrateRepositoryFactory = SubstrateRepositoryFactory(
            storageFacade: UserDataStorageFacade.shared
        )

        let accountInfoRepository = substrateRepositoryFactory.createAccountInfoStorageItemRepository()

        let accountInfoFetchingProvider = AccountInfoFetching(
            accountInfoRepository: accountInfoRepository,
            chainRegistry: ChainRegistryFacade.sharedRegistry,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let viewModelFactory = AssetManagementViewModelFactoryDefault(
            assetBalanceFormatterFactory: AssetBalanceFormatterFactory()
        )

        let repository = SubstrateRepositoryFactory(
            storageFacade: UserDataStorageFacade.shared
        ).createAccountInfoStorageItemRepository()
        let ethereumBalanceRepositoryWrapper = EthereumBalanceRepositoryCacheWrapper(
            logger: Logger.shared,
            repository: repository,
            operationManager: OperationManagerFacade.sharedManager
        )

        let runtimeMetadataRepository: AsyncCoreDataRepositoryDefault<RuntimeMetadataItem, CDRuntimeMetadataItem> =
            SubstrateDataStorageFacade.shared.createAsyncRepository()

        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let ethereumRemoteBalanceFetching = EthereumRemoteBalanceFetching(
            chainRegistry: chainRegistry,
            repositoryWrapper: ethereumBalanceRepositoryWrapper
        )

        let storagePerformer = SSFStorageQueryKit.StorageRequestPerformerDefault(
            chainRegistry: chainRegistry
        )

        let accountInfoRemote = AccountInfoRemoteServiceDefault(
            runtimeItemRepository: AsyncAnyRepository(runtimeMetadataRepository),
            ethereumRemoteBalanceFetching: ethereumRemoteBalanceFetching,
            storagePerformer: storagePerformer
        )

        let interactor = AssetManagementInteractor(
            chainAssetFetching: chainAssetFetching,
            priceLocalSubscriber: priceLocalSubscriber,
            accountInfoFetchingProvider: accountInfoFetchingProvider,
            eventCenter: EventCenter.shared,
            accountInfoRemoteService: accountInfoRemote
        )
        let router = AssetManagementRouter()

        let presenter = AssetManagementPresenter(
            wallet: wallet,
            networkFilter: networkFilter,
            logger: Logger.shared,
            viewModelFactory: viewModelFactory,
            interactor: interactor,
            router: router,
            localizationManager: localizationManager
        )

        let view = AssetManagementViewController(
            output: presenter,
            localizationManager: localizationManager
        )

        return (view, presenter)
    }
}
