import SoraFoundation
import CommonWallet
import BigInt

protocol StakingBondMoreViewProtocol: ControllerBackedProtocol, Localizable {
    func didReceiveInput(viewModel: LocalizableResource<AmountInputViewModelProtocol>)
    func didReceiveAsset(viewModel: LocalizableResource<AssetBalanceViewModelProtocol>)
    func didReceiveFee(viewModel: LocalizableResource<BalanceViewModelProtocol>?)
}

protocol StakingBondMorePresenterProtocol: AnyObject {
    func setup()
    func handleContinueAction()
    func updateAmount(_ newValue: Decimal)
    func selectAmountPercentage(_ percentage: Float)
}

protocol StakingBondMoreInteractorInputProtocol: AnyObject {
    func setup()
    func estimateFee(reuseIdentifier: String?, builderClosure: ExtrinsicBuilderClosure?)
}

protocol StakingBondMoreInteractorOutputProtocol: AnyObject {
    func didReceivePriceData(result: Result<PriceData?, Error>)
}

protocol StakingBondMoreWireframeProtocol: AlertPresentable, ErrorPresentable, StakingErrorPresentable {
    func showConfirmation(
        from view: ControllerBackedProtocol?,
        flow: StakingBondMoreConfirmationFlow,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    )

    func close(view: ControllerBackedProtocol?)
}
