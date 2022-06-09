import Foundation
import RobinHood

final class SelectValidatorsStartPresenter {
    weak var view: SelectValidatorsStartViewProtocol?
    let wireframe: SelectValidatorsStartWireframeProtocol
    let interactor: SelectValidatorsStartInteractorInputProtocol

    let logger: LoggerProtocol?
    let chainAsset: ChainAsset
    let wallet: MetaAccountModel
    let viewModelState: SelectValidatorsStartViewModelState
    let viewModelFactory: SelectValidatorsStartViewModelFactoryProtocol

    private var electedValidators: [AccountAddress: ElectedValidatorInfo]?
    private var recommendedValidators: [ElectedValidatorInfo]?
    private var selectedValidators: SharedList<SelectedValidatorInfo>?
    private var maxNominations: Int?

    init(
        interactor: SelectValidatorsStartInteractorInputProtocol,
        wireframe: SelectValidatorsStartWireframeProtocol,
        logger: LoggerProtocol? = nil,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        viewModelState: SelectValidatorsStartViewModelState,
        viewModelFactory: SelectValidatorsStartViewModelFactoryProtocol
    ) {
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.interactor = interactor
        self.wireframe = wireframe
        self.logger = logger
        self.viewModelState = viewModelState
        self.viewModelFactory = viewModelFactory
    }

    private func updateView() {
        guard
            let maxNominations = maxNominations,
            let selectedValidators = selectedValidators else {
            return
        }

        let viewModel = SelectValidatorsStartViewModel(
            selectedCount: selectedValidators.count,
            totalCount: maxNominations
        )

        view?.didReceive(viewModel: viewModel)
    }

    private func handle(error: Error) {
        logger?.error("Did receive error \(error)")

        let locale = view?.localizationManager?.selectedLocale
        if !wireframe.present(error: error, from: view, locale: locale) {
            _ = wireframe.present(
                error: BaseOperationError.unexpectedDependentResult,
                from: view,
                locale: locale
            )
        }
    }
}

extension SelectValidatorsStartPresenter: SelectValidatorsStartPresenterProtocol {
    func setup() {
        interactor.setup()

        viewModelState.setStateListener(self)
    }

    func updateOnAppearance() {
        updateView()
    }

    func selectRecommendedValidators() {
        guard let recommendedValidatorListFlow = viewModelState.recommendedValidatorListFlow else {
            return
        }

        wireframe.proceedToRecommendedList(
            from: view,
            flow: recommendedValidatorListFlow,
            wallet: wallet,
            chainAsset: chainAsset
        )
    }

    func selectCustomValidators() {
        guard let flow = viewModelState.customValidatorListFlow else {
            return
        }

        wireframe.proceedToCustomList(
            from: view,
            flow: flow,
            chainAsset: chainAsset,
            wallet: wallet
        )
    }
}

extension SelectValidatorsStartPresenter: SelectValidatorsStartModelStateListener {
    func didReceiveError(error: Error) {
        handle(error: error)
    }

    func modelStateDidChanged(viewModelState: SelectValidatorsStartViewModelState) {
        guard let viewModel = viewModelFactory.buildViewModel(viewModelState: viewModelState) else {
            return
        }

        view?.didReceive(viewModel: viewModel)
    }
}

extension SelectValidatorsStartPresenter: SelectValidatorsStartInteractorOutputProtocol {}
