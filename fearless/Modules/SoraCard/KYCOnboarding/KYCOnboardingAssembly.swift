import UIKit
import SoraFoundation

final class KYCOnboardingAssembly {
    static func configureModule(data: SCKYCUserDataModel) -> KYCOnboardingModuleCreationResult? {
        let localizationManager = LocalizationManager.shared
        let service: SCKYCService = .init(client: .shared)
        let storage: SCStorage = .shared
        let interactor = KYCOnboardingInteractor(
            service: service,
            storage: storage,
            data: data
        )
        let router = KYCOnboardingRouter()

        let presenter = KYCOnboardingPresenter(
            interactor: interactor,
            router: router,
            logger: Logger.shared,
            localizationManager: localizationManager
        )

        let view = KYCOnboardingViewController(
            output: presenter,
            localizationManager: localizationManager
        )

        return (view, presenter)
    }
}