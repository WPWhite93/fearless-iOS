import Foundation

protocol ProfileViewProtocol: ControllerBackedProtocol {
    func didReceive(state: ProfileViewState)
}

protocol ProfilePresenterProtocol: AnyObject {
    func didLoad(view: ProfileViewProtocol)
    func activateAccountDetails()
    func activateOption(_ option: ProfileOption)
    func logout()
    func switcherValueChanged(isOn: Bool, index: Int)
}

protocol ProfileInteractorInputProtocol: AnyObject {
    func setup(with output: ProfileInteractorOutputProtocol)
    func updateWallet(_ wallet: MetaAccountModel)
    func logout(completion: @escaping () -> Void)
    func update(currency: Currency)
    func update(zeroBalanceAssetsHidden: Bool)
    func prepareStartSoraCard() async
}

protocol ProfileInteractorOutputProtocol: AnyObject {
    func didReceive(wallet: MetaAccountModel)
    func didReceiveUserDataProvider(error: Error)
    func didRecieve(selectedCurrency: Currency)
    func didReceiveWalletBalances(_ balances: Result<[MetaAccountId: WalletBalanceInfo], Error>)
    func didReceive(kycStatuses: [SCKYCStatusResponse])
    func didReceive(error: NetworkingError)
    func restartKYC()
}

protocol ProfileWireframeProtocol: ErrorPresentable,
    SheetAlertPresentable,
    WebPresentable,
    ModalAlertPresenting,
    AddressOptionsPresentable,
    AccountManagementPresentable {
    func showAccountDetails(
        from view: ProfileViewProtocol?,
        metaAccount: MetaAccountModel
    )
    func showAccountSelection(
        from view: ProfileViewProtocol?,
        moduleOutput: WalletsManagmentModuleOutput
    )
    func showLanguageSelection(from view: ProfileViewProtocol?)
    func showPincodeChange(from view: ProfileViewProtocol?)
    func showAbout(from view: ProfileViewProtocol?)
    func logout(from view: ProfileViewProtocol?)
    func showCheckPincode(
        from view: ProfileViewProtocol?,
        output: CheckPincodeModuleOutput
    )
    func showSelectCurrency(from view: ProfileViewProtocol?, with: MetaAccountModel)
    func close(view: ControllerBackedProtocol?)
    func showPolkaswapDisclaimer(from view: ControllerBackedProtocol?)
    func startKYC(from view: ControllerBackedProtocol?, data: SCKYCUserDataModel, wallet: MetaAccountModel)
    func showKYCVerificationStatus(from view: ControllerBackedProtocol?)
}

protocol ProfileViewFactoryProtocol: AnyObject {
    static func createView() -> ProfileViewProtocol?
}
