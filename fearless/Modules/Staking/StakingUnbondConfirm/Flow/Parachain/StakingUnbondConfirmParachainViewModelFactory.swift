import Foundation
import FearlessUtils
import SoraFoundation

final class StakingUnbondConfirmParachainViewModelFactory: StakingUnbondConfirmViewModelFactoryProtocol {
    let asset: AssetModel
    let bondingDuration: UInt32?

    private lazy var formatterFactory = AssetBalanceFormatterFactory()
    private var iconGenerator: IconGenerating

    init(
        asset: AssetModel,
        bondingDuration: UInt32?,
        iconGenerator: IconGenerating
    ) {
        self.asset = asset
        self.bondingDuration = bondingDuration
        self.iconGenerator = iconGenerator
    }

    private func createHints(from _: Bool)
        -> LocalizableResource<[TitleIconViewModel]> {
        LocalizableResource { locale in
            var items = [TitleIconViewModel]()

            items.append(
                TitleIconViewModel(
                    title: R.string.localizable.stakingStakeLessHint(preferredLanguages: locale.rLanguages),
                    icon: R.image.iconInfoFilled()?.tinted(with: R.color.colorStrokeGray()!)
                )
            )

            return items
        }
    }

    func buildViewModel(viewModelState: StakingUnbondConfirmViewModelState) -> StakingUnbondConfirmViewModel? {
        guard let viewModelState = viewModelState as? StakingUnbondConfirmParachainViewModelState else {
            return nil
        }

        let formatter = formatterFactory.createInputFormatter(for: asset.displayInfo)

        let amount = LocalizableResource { locale in
            formatter.value(for: locale).string(from: viewModelState.inputAmount as NSNumber) ?? ""
        }

        let address = viewModelState.accountAddress ?? ""
        let accountIcon = try? iconGenerator.generateFromAddress(address)

        let collatorIcon = try? iconGenerator.generateFromAddress(viewModelState.candidate.address)

        let hints = createHints(from: false)

        return StakingUnbondConfirmViewModel(
            senderAddress: address,
            senderIcon: accountIcon,
            senderName: viewModelState.wallet.fetch(for: viewModelState.chainAsset.chain.accountRequest())?.name,
            collatorName: viewModelState.candidate.identity?.name,
            collatorIcon: collatorIcon,
            amount: amount,
            hints: hints
        )
    }

    func buildBondingDurationViewModel(
        viewModelState: StakingUnbondConfirmViewModelState
    ) -> LocalizableResource<TitleWithSubtitleViewModel>? {
        guard let viewModelState = viewModelState as? StakingUnbondConfirmParachainViewModelState else {
            return nil
        }

        let daysCount = bondingDuration.map { UInt32($0) / viewModelState.chainAsset.chain.erasPerDay }
        let viewModel: LocalizableResource<TitleWithSubtitleViewModel> = LocalizableResource { locale in
            guard let daysCount = daysCount else {
                return TitleWithSubtitleViewModel(title: "")
            }

            let title = R.string.localizable.stakingUnbondingPeriod_v190(preferredLanguages: locale.rLanguages)
            let subtitle = R.string.localizable.commonDaysFormat(
                format: Int(daysCount),
                preferredLanguages: locale.rLanguages
            )
            return TitleWithSubtitleViewModel(title: title, subtitle: subtitle)
        }
        return viewModel
    }
}