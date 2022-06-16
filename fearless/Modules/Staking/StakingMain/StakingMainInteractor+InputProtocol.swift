import Foundation
import SoraFoundation
import RobinHood

extension StakingMainInteractor: StakingMainInteractorInputProtocol {
    func updatePrices() {
        updateAfterChainAssetSave()
        updateAfterSelectedAccountChange()
    }

    func saveNetworkInfoViewExpansion(isExpanded: Bool) {
        commonSettings.stakingNetworkExpansion = isExpanded
    }

    func setup() {
        setupSelectedAccountAndChainAsset()

        //  Only relaychain, check if it ever needed for parachain
        setupChainRemoteSubscription()
        setupAccountRemoteSubscription()

        sharedState.eraValidatorService.setup()
        sharedState.rewardCalculationService.setup()

        eraInfoOperationFactory = selectedChainAsset?.chain.isEthereumBased == true ? ParachainStakingInfoOperationFactory() : RelaychainStakingInfoOperationFactory()

        provideNewChain()
        provideSelectedAccount()

        guard
            let chainId = selectedChainAsset?.chain.chainId,
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainId) else {
            return
        }

        //  Only relaychain
        provideMaxNominatorsPerValidator(from: runtimeService)

        performPriceSubscription()
        performAccountInfoSubscription()

        //  Only relaychain
        performStashControllerSubscription()
        performNominatorLimitsSubscripion()

        //  Should be done by separate task
        provideRewardCalculator(from: sharedState.rewardCalculationService)
        provideEraStakersInfo(from: sharedState.eraValidatorService)

        provideNetworkStakingInfo()

        eventCenter.add(observer: self, dispatchIn: .main)

        applicationHandler.delegate = self

        presenter?.networkInfoViewExpansion(isExpanded: commonSettings.stakingNetworkExpansion)

//        Mock

        presenter?.didReceive(delegatorState: nil)
    }

    func save(chainAsset: ChainAsset) {
        guard selectedChainAsset?.chainAssetId != chainAsset.chainAssetId else {
            return
        }

        stakingSettings.save(value: chainAsset, runningCompletionIn: .main) { [weak self] _ in
            self?.updateAfterChainAssetSave()
            self?.updateAfterSelectedAccountChange()
        }
    }

    private func updateAfterChainAssetSave() {
        guard let newSelectedChainAsset = stakingSettings.value else {
            return
        }

        // TODO: replace isEthereumBased with real relaychain/parachain parameter
        eraInfoOperationFactory = newSelectedChainAsset.chain.isEthereumBased ? ParachainStakingInfoOperationFactory() : RelaychainStakingInfoOperationFactory()

        selectedChainAsset.map { clearChainRemoteSubscription(for: $0.chain.chainId) }

        selectedChainAsset = newSelectedChainAsset

        setupChainRemoteSubscription()

        updateSharedState()

        provideNewChain()

        clear(singleValueProvider: &priceProvider)
        performPriceSubscription()

        clearNominatorsLimitProviders()
        performNominatorLimitsSubscripion()

        clearStashControllerSubscription()
        performStashControllerSubscription()

        guard
            let chainId = selectedChainAsset?.chain.chainId,
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainId) else {
            return
        }

        provideEraStakersInfo(from: sharedState.eraValidatorService)
        provideNetworkStakingInfo()
        provideRewardCalculator(from: sharedState.rewardCalculationService)
        provideMaxNominatorsPerValidator(from: runtimeService)
    }

    private func updateAfterSelectedAccountChange() {
        clearAccountRemoteSubscription()
        accountInfoSubscriptionAdapter.reset()
        clearStashControllerSubscription()

        guard let selectedChain = selectedChainAsset?.chain,
              let selectedMetaAccount = selectedWalletSettings.value,
              let newSelectedAccount = selectedMetaAccount.fetch(for: selectedChain.accountRequest()) else {
            return
        }

        selectedAccount = newSelectedAccount

        setupAccountRemoteSubscription()

        performAccountInfoSubscription()

        provideSelectedAccount()

        performStashControllerSubscription()
    }
}

extension StakingMainInteractor: EventVisitorProtocol {
    func processSelectedAccountChanged(event _: SelectedAccountChanged) {
        updateAfterSelectedAccountChange()
    }

    func processEraStakersInfoChanged(event _: EraStakersInfoChanged) {
        provideNetworkStakingInfo()
        provideEraStakersInfo(from: sharedState.eraValidatorService)
        provideRewardCalculator(from: sharedState.rewardCalculationService)
    }

    func processChainsUpdated(event: ChainsUpdatedEvent) {
        guard event.updatedChains.contains(where: {
            $0.identifier == selectedChainAsset?.chain.identifier
        }) else { return }
        updateAfterChainAssetSave()
        updateAfterSelectedAccountChange()
    }

    func processMetaAccountChanged(event _: MetaAccountModelChangedEvent) {
        priceProvider?.refresh()
    }
}

extension StakingMainInteractor: ApplicationHandlerDelegate {
    func didReceiveDidBecomeActive(notification _: Notification) {
        priceProvider?.refresh()
        totalRewardProvider?.refresh()
        rewardAnalyticsProvider?.refresh()
    }
}
