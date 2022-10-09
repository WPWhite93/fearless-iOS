import Foundation
import UIKit

protocol StakingPoolInfoViewModelFactoryProtocol {
    func buildViewModel(
        stashAccount: AccountId,
        electedValidators: [ElectedValidatorInfo],
        stakingPool: StakingPool,
        priceData: PriceData?,
        locale: Locale
    ) -> StakingPoolInfoViewModel
}

final class StakingPoolInfoViewModelFactory {
    private let chainAsset: ChainAsset
    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol

    init(chainAsset: ChainAsset, balanceViewModelFactory: BalanceViewModelFactoryProtocol) {
        self.chainAsset = chainAsset
        self.balanceViewModelFactory = balanceViewModelFactory
    }
}

extension StakingPoolInfoViewModelFactory: StakingPoolInfoViewModelFactoryProtocol {
    func buildViewModel(
        stashAccount: AccountId,
        electedValidators: [ElectedValidatorInfo],
        stakingPool: StakingPool,
        priceData: PriceData?,
        locale: Locale
    ) -> StakingPoolInfoViewModel {
        let staked = Decimal.fromSubstrateAmount(
            stakingPool.info.points,
            precision: Int16(chainAsset.asset.precision)
        ) ?? 0.0
        let stakedAmountViewModel = balanceViewModelFactory.balanceFromPrice(staked, priceData: priceData)

        let selectedValidators = electedValidators.map { validator in
            validator.toSelected(for: try? stashAccount.toAddress(using: chainAsset.chain.chainFormat))
        }.filter { $0.isActive }

        let fullString = NSMutableAttributedString(string: "\(selectedValidators.count)" + "  ")

        let imageAttachment = NSTextAttachment()
        imageAttachment.image = R.image.dropTriangle()
        imageAttachment.bounds = CGRect(
            x: 0,
            y: 3,
            width: 12,
            height: 6
        )

        let imageString = NSAttributedString(attachment: imageAttachment)
        fullString.append(imageString)

        return StakingPoolInfoViewModel(
            indexTitle: stakingPool.id,
            name: stakingPool.name,
            state: stakingPool.info.state.rawValue,
            stakedAmountViewModel: stakedAmountViewModel.value(for: locale),
            membersCountTitle: "\(stakingPool.info.memberCounter)",
            validatorsCount: fullString,
            depositorName: try? stakingPool.info.roles.depositor.toAddress(using: chainAsset.chain.chainFormat),
            rootName: try? stakingPool.info.roles.root?.toAddress(using: chainAsset.chain.chainFormat),
            nominatorName: try? stakingPool.info.roles.nominator?.toAddress(using: chainAsset.chain.chainFormat),
            stateTogglerName: try? stakingPool.info.roles.stateToggler?.toAddress(using: chainAsset.chain.chainFormat)
        )
    }
}
