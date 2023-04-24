import UIKit
import SoraFoundation
import SoraUI

final class VerificationStatusViewController: UIViewController, ViewHolder {
    typealias RootViewType = VerificationStatusViewLayout

    // MARK: Private properties

    private let output: VerificationStatusViewOutput
    private var error: Error?

    // MARK: - Constructor

    init(
        output: VerificationStatusViewOutput,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func loadView() {
        view = VerificationStatusViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.didLoad(view: self)

        configureButtons()
    }

    // MARK: - Private methods

    @objc private func actionButtonClicked() {
        output.didTapActionButton()
    }

    @objc private func supportButtonClicked() {
        output.didTapSupportButton()
    }

    private func configureButtons() {
        rootView.actionButton.addTarget(
            self,
            action: #selector(actionButtonClicked),
            for: .touchUpInside
        )

        rootView.supportButton.addTarget(
            self,
            action: #selector(supportButtonClicked),
            for: .touchUpInside
        )
    }
}

// MARK: - VerificationStatusViewInput

extension VerificationStatusViewController: VerificationStatusViewInput {
    func didReceive(status: SoraCardStatus) {
        error = nil

        rootView.bind(status: status)

        reloadEmptyState(animated: true)
    }

    func didReceive(error: Error?) {
        self.error = error

        reloadEmptyState(animated: true)
    }
}

// MARK: - Localizable

extension VerificationStatusViewController: Localizable {
    func applyLocalization() {
        rootView.locale = selectedLocale
    }
}

extension VerificationStatusViewController: LoadableViewProtocol {
    var loadableContentView: UIView { rootView.contentView }
}

extension VerificationStatusViewController: EmptyStateViewOwnerProtocol {
    var emptyStateDelegate: EmptyStateDelegate { self }
    var emptyStateDataSource: EmptyStateDataSource { self }
    var contentViewForEmptyState: UIView { rootView.contentView }
}

extension VerificationStatusViewController: EmptyStateDataSource {
    var viewForEmptyState: UIView? {
        let errorView = ErrorStateView()
        errorView.errorDescriptionLabel.text = error?.localizedDescription
        errorView.delegate = self
        errorView.locale = selectedLocale
        return errorView
    }
}

extension VerificationStatusViewController: EmptyStateDelegate {
    var shouldDisplayEmptyState: Bool {
        error != nil
    }
}

extension VerificationStatusViewController: ErrorStateViewDelegate {
    func didRetry(errorView _: ErrorStateView) {
        output.didTapRefresh()
    }
}

extension VerificationStatusViewController: HiddableBarWhenPushed {}