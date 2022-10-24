import SoraFoundation

protocol YourValidatorListViewProtocol: ControllerBackedProtocol, Localizable, LoadableViewProtocol {
    func reload(state: YourValidatorListViewState)
}

protocol YourValidatorListPresenterProtocol: AnyObject {
    func setup()
    func retry()
    func didSelectValidator(viewModel: YourValidatorViewModel)
    func changeValidators()
}

protocol YourValidatorListInteractorInputProtocol: AnyObject {
    func setup()
    func refresh()
}

protocol YourValidatorListInteractorOutputProtocol: AnyObject {}

protocol YourValidatorListWireframeProtocol: AlertPresentable, ErrorPresentable,
    StakingErrorPresentable {
    func present(
        flow: ValidatorInfoFlow,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        from view: YourValidatorListViewProtocol?
    )

    func proceedToSelectValidatorsStart(
        from view: YourValidatorListViewProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        flow: SelectValidatorsStartFlow
    )
}
