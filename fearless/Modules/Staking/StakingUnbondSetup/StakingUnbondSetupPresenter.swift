import Foundation
import SoraFoundation
import BigInt

final class StakingUnbondSetupPresenter {
    weak var view: StakingUnbondSetupViewProtocol?
    let wireframe: StakingUnbondSetupWireframeProtocol
    let interactor: StakingUnbondSetupInteractorInputProtocol

    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    let viewModelFactory: StakingUnbondSetupViewModelFactoryProtocol
    let viewModelState: StakingUnbondSetupViewModelState
    let logger: LoggerProtocol?
    let chainAsset: ChainAsset
    let wallet: MetaAccountModel

    private var priceData: PriceData?

    init(
        interactor: StakingUnbondSetupInteractorInputProtocol,
        wireframe: StakingUnbondSetupWireframeProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        viewModelFactory: StakingUnbondSetupViewModelFactoryProtocol,
        viewModelState: StakingUnbondSetupViewModelState,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.viewModelFactory = viewModelFactory
        self.viewModelState = viewModelState
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.logger = logger
    }
}

extension StakingUnbondSetupPresenter: StakingUnbondSetupPresenterProtocol {
    func setup() {
        viewModelState.setStateListener(self)

        provideInputViewModel()
        provideFeeViewModel()
        provideBondingDuration()
        provideAssetViewModel()

        interactor.setup()

        interactor.estimateFee(builderClosure: viewModelState.builderClosure)
    }

    func selectAmountPercentage(_ percentage: Float) {
        viewModelState.selectAmountPercentage(percentage)
    }

    func updateAmount(_ amount: Decimal) {
        viewModelState.updateAmount(amount)
    }

    func proceed() {
        let locale = view?.localizationManager?.selectedLocale ?? Locale.current
        DataValidationRunner(validators: viewModelState.validators(using: locale)).runValidation { [weak self] in
            guard let strongSelf = self else {
                return
            }

            if let amount = strongSelf.viewModelState.inputAmount {
                strongSelf.wireframe.proceed(
                    view: strongSelf.view,
                    flow: .relaychain(amount: amount),
                    chainAsset: strongSelf.chainAsset,
                    wallet: strongSelf.wallet
                )
            } else {
                strongSelf.logger?.warning("Missing amount after validation")
            }
        }
    }

    func close() {
        wireframe.close(view: view)
    }
}

extension StakingUnbondSetupPresenter: StakingUnbondSetupInteractorOutputProtocol {
    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData
            provideAssetViewModel()
            provideFeeViewModel()
        case let .failure(error):
            logger?.error("Price data subscription error: \(error)")
        }
    }
}

extension StakingUnbondSetupPresenter: StakingUnbondSetupModelStateListener {
    func provideInputViewModel() {
        let inputView = balanceViewModelFactory.createBalanceInputViewModel(viewModelState.inputAmount)
        view?.didReceiveInput(viewModel: inputView)
    }

    func provideFeeViewModel() {
        if let fee = viewModelState.fee {
            let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
            view?.didReceiveFee(viewModel: feeViewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    func provideAssetViewModel() {
        let viewModel = balanceViewModelFactory.createAssetBalanceViewModel(
            viewModelState.inputAmount ?? 0.0,
            balance: viewModelState.bonded,
            priceData: priceData
        )

        view?.didReceiveAsset(viewModel: viewModel)
    }

    func provideBondingDuration() {
        guard let bondingDurationViewModel = viewModelFactory.buildBondingDurationViewModel(viewModelState: viewModelState) else {
            return
        }

        view?.didReceiveBonding(duration: bondingDurationViewModel)
    }

    func updateFeeIfNeeded() {
        interactor.estimateFee(builderClosure: viewModelState.builderClosure)
    }

    func didReceiveError(error: Error) {
        logger?.error("StakingUnbondSetupPresenter didReceiveError: \(error)")
    }
}
