import Foundation
import RobinHood
import SoraFoundation

final class WalletDetailsViewFactory {
    static func createView(
        with selectedWallet: MetaAccountModel
    ) -> WalletDetailsViewProtocol {
        let chainsRepository = ChainRepositoryFactory().createRepository(
            sortDescriptors: [NSSortDescriptor.chainsByAddressPrefix]
        )

        let interactor = WalletDetailsInteractor(
            selectedMetaAccount: selectedWallet,
            chainsRepository: AnyDataProviderRepository(chainsRepository),
            operationManager: OperationManagerFacade.sharedManager,
            eventCenter: EventCenter.shared,
            repository: AccountRepositoryFactory.createRepository()
        )

        let wireframe = WalletDetailsWireframe()

        let localizationManager = LocalizationManager.shared
        let presenter = WalletDetailsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            selectedWallet: selectedWallet,
            localizationManager: localizationManager
        )
        interactor.presenter = presenter

        let view = WalletDetailsViewController(output: presenter)
        return view
    }
}
