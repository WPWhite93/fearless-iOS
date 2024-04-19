import UIKit
import SoraUI
import SnapKit

final class ChainAssetListViewLayout: UIView {
    private enum Constants {
        static let tableViewContentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: UIConstants.actionHeight,
            right: 0
        )
    }

    var locale: Locale?

    enum ViewState {
        case normal
        case empty
    }

    var keyboardAdoptableConstraint: Constraint?

    weak var bannersView: UIView?

    var headerViewContainer: UIStackView = {
        let view = UIFactory.default.createVerticalStackView(spacing: UIConstants.bigOffset)
        view.alignment = .center
        return view
    }()

    let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.contentInset = Constants.tableViewContentInset
        view.refreshControl = UIRefreshControl()
        return view
    }()

    var isAnimating = false

    // MARK: - Manage button

    let assetManagementButton: TriangularedButton = {
        let button = TriangularedButton()
        button.triangularedView?.shadowOpacity = 0
        button.triangularedView?.fillColor = R.color.colorWhite8()!
        button.triangularedView?.highlightedFillColor = R.color.colorWhite8()!
        button.imageWithTitleView?.titleColor = R.color.colorWhite()!
        button.imageWithTitleView?.titleFont = .h4Title
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addBanners(view: UIView) {
        bannersView = view
        bannersView?.isHidden = true
        headerViewContainer.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(UIConstants.bigOffset)
        }
    }

    func setHeaderView() {
        tableView.tableHeaderView = headerViewContainer
        headerViewContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    func removeHeaderView() {
        headerViewContainer.removeFromSuperview()
        tableView.tableHeaderView = nil
    }

    func setFooterView() {
        let size = CGSize(width: tableView.bounds.width, height: UIConstants.actionHeight)
        let footerContainer = UIView(frame: CGRect(origin: .zero, size: size))
        footerContainer.addSubview(assetManagementButton)
        assetManagementButton.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.height.equalTo(UIConstants.actionHeight)
        }
        tableView.tableFooterView = footerContainer
    }

    func removeFooterView() {
        assetManagementButton.removeFromSuperview()
        tableView.tableFooterView = nil
    }

    func viewForEmptyState(for state: AssetListState) -> UIView {
        let emptyView = EmptyView()
        emptyView.image = R.image.iconWarning()
        emptyView.title = R.string.localizable.emptyViewTitle(preferredLanguages: locale?.rLanguages)
        emptyView.text = emptyViewText(for: state)
        emptyView.iconMode = .bigFilledShadow

        let container = ScrollableContainerView()
        container.stackView.spacing = 16
        container.addArrangedSubview(headerViewContainer)
        container.addArrangedSubview(emptyView)
        container.addArrangedSubview(assetManagementButton)

        headerViewContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
        }

        assetManagementButton.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(UIConstants.actionHeight)
        }

        return container
    }

    func runManageAssetAnimate(finish: @escaping (() -> Void)) {
        isAnimating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let rect = self.tableView.convert(
                self.assetManagementButton.bounds,
                from: self.tableView.tableFooterView
            )
            self.tableView.scrollRectToVisible(
                rect,
                animated: true
            )

            UIView.animate(
                withDuration: 0.6,
                delay: 0.2,
                animations: {
                    self.assetManagementButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.6) {
                        self.assetManagementButton.transform = CGAffineTransform.identity
                        finish()
                        self.isAnimating = false
                    }
                }
            )
        }
    }

    func setFooterButtonTitle(for state: AssetListState) {
        let title: String?
        switch state {
        case .defaultList, .allIsHidden:
            title = R.string.localizable.walletManageAssets(preferredLanguages: locale?.rLanguages)
        case .chainHasNetworkIssue:
            title = R.string.localizable.tryAgain(preferredLanguages: locale?.rLanguages)
        case .chainHasAccountIssue:
            title = R.string.localizable.accountsAddAccount(preferredLanguages: locale?.rLanguages)
        case .search:
            title = nil
        }
        assetManagementButton.imageWithTitleView?.title = title
    }

    private func setupLayout() {
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            keyboardAdoptableConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    private func emptyViewText(for state: AssetListState) -> String? {
        switch state {
        case .defaultList:
            return nil
        case .allIsHidden:
            return R.string.localizable.walletAllAssetsHidden(preferredLanguages: locale?.rLanguages)
        case .chainHasNetworkIssue:
            return "Connection Error: Unable to connect to the network. Please try again."
        case .chainHasAccountIssue:
            return R.string.localizable.accountNeededMessage(preferredLanguages: locale?.rLanguages)
        case .search:
            return R.string.localizable.emptyViewDescription(preferredLanguages: locale?.rLanguages)
        }
    }
}
