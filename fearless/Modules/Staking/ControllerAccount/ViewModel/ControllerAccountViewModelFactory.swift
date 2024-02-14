import IrohaCrypto
import SoraFoundation
import SSFUtils
import SSFModels

final class ControllerAccountViewModelFactory: ControllerAccountViewModelFactoryProtocol {
    let iconGenerator: IconGenerating
    let currentAccountItem: ChainAccountResponse

    init(currentAccountItem: ChainAccountResponse, iconGenerator: IconGenerating) {
        self.currentAccountItem = currentAccountItem
        self.iconGenerator = iconGenerator
    }

    func createViewModel(
        stashItem: StashItem,
        stashAccountItem: ChainAccountResponse?,
        chosenAccountItem: ChainAccountResponse?,
        chainAsset: ChainAsset
    ) -> ControllerAccountViewModel {
        let stashAddress = stashItem.stash
        let stashViewModel = LocalizableResource<AccountInfoViewModel> { locale in
            let stashIcon = try? self.iconGenerator
                .generateFromAddress(stashAddress)
                .imageWithFillColor(
                    R.color.colorWhite()!,
                    size: UIConstants.smallAddressIconSize,
                    contentScale: UIScreen.main.scale
                )
            return AccountInfoViewModel(
                title: R.string.localizable.stackingStashAccount(preferredLanguages: locale.rLanguages),
                address: stashAddress,
                name: stashAccountItem?.name ?? stashAddress,
                icon: stashIcon
            )
        }

        let controllerViewModel = LocalizableResource<AccountInfoViewModel> { locale in
            let selectedControllerAddress = chosenAccountItem?.toAddress() ?? stashItem.controller
            let controllerIcon = try? self.iconGenerator
                .generateFromAddress(selectedControllerAddress)
                .imageWithFillColor(
                    R.color.colorWhite()!,
                    size: UIConstants.smallAddressIconSize,
                    contentScale: UIScreen.main.scale
                )
            return AccountInfoViewModel(
                title: R.string.localizable.stakingControllerAccountTitle(preferredLanguages: locale.rLanguages),
                address: selectedControllerAddress,
                name: chosenAccountItem?.name ?? selectedControllerAddress,
                icon: controllerIcon
            )
        }

        let currentAccountIsController =
            (stashItem.stash != stashItem.controller) &&
            stashItem.controller == currentAccountItem.toAddress()

        return ControllerAccountViewModel(
            chainAsset: chainAsset,
            stashViewModel: stashViewModel,
            controllerViewModel: controllerViewModel,
            currentAccountIsController: currentAccountIsController,
            actionButtonIsEnabled: !currentAccountIsController
        )
    }
}
