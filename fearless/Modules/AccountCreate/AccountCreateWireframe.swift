import Foundation
import IrohaCrypto

final class AccountCreateWireframe: AccountCreateWireframeProtocol {
    func confirm(
        from view: AccountCreateViewProtocol?,
        request: MetaAccountCreationRequest,
        mnemonic: [String]
    ) {
        guard let accountConfirmation = AccountConfirmViewFactory
            .createViewForOnboarding(request: request, mnemonic: mnemonic)?.controller
        else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(accountConfirmation, animated: true)
        }
    }

    func presentCryptoTypeSelection(
        from view: AccountCreateViewProtocol?,
        availableTypes: [MultiassetCryptoType],
        selectedType: MultiassetCryptoType,
        delegate: ModalPickerViewControllerDelegate?,
        context: AnyObject?
    ) {
        guard let modalPicker = ModalPickerFactory.createPickerForList(
            availableTypes,
            selectedType: selectedType,
            delegate: delegate,
            context: context
        ) else {
            return
        }

        view?.controller.navigationController?.present(
            modalPicker,
            animated: true,
            completion: nil
        )
    }
}
