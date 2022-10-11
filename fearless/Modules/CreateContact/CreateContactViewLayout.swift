import UIKit

final class CreateContactViewLayout: UIView {
    enum LayoutConstants {
        static let stackViewSpacing: CGFloat = 12
    }

    let navigationBar: BaseNavigationBar = {
        let bar = BaseNavigationBar()
        bar.set(.push)
        bar.backButton.backgroundColor = R.color.colorWhite8()
        bar.backButton.rounded()
        bar.backgroundColor = R.color.colorBlack19()
        return bar
    }()

    var locale = Locale.current {
        didSet {
            applyLocalization()
            backgroundColor = R.color.colorAlmostBlack()

            setupLayout()
        }
    }

    let selectNetworkView = UIFactory.default.createSelectNetworkView()
    let contactNameField = TriangularedTextField()
    let contactAddressField: TriangularedTextField = {
        let view = TriangularedTextField()
        if let oldStyle = view.textField.defaultTextAttributes[
            .paragraphStyle,
            default: NSParagraphStyle()
        ] as? NSParagraphStyle,
            let style: NSMutableParagraphStyle = oldStyle.mutableCopy() as? NSParagraphStyle as? NSMutableParagraphStyle {
            style.lineBreakMode = .byTruncatingMiddle
            view.textField.defaultTextAttributes[.paragraphStyle] = style
        }
        return view
    }()

    private let contentView: ScrollableContainerView = {
        let view = ScrollableContainerView()
        view.stackView.isLayoutMarginsRelativeArrangement = true
        view.stackView.layoutMargins = UIEdgeInsets(top: 24.0, left: 0.0, bottom: 0.0, right: 0.0)
        view.stackView.spacing = UIConstants.bigOffset
        return view
    }()

    let createButton: TriangularedButton = {
        let button = TriangularedButton()
        button.set(enabled: false)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = R.color.colorBlack19()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        navigationBar.backButton.layer.cornerRadius = navigationBar.backButton.frame.size.height / 2
    }

    func bind(viewModel: CreateContactViewModel) {
        contactAddressField.textField.text = viewModel.address
        selectNetworkView.subtitle = viewModel.chainName
        viewModel.iconViewModel?.cancel(on: selectNetworkView.iconView)
        selectNetworkView.iconView.image = nil
        viewModel.iconViewModel?.loadAmountInputIcon(on: selectNetworkView.iconView, animated: true)
    }

    func updateState(isValid: Bool) {
        createButton.set(enabled: isValid)
    }

    private func setupLayout() {
        addSubview(navigationBar)
        addSubview(contentView)
        addSubview(createButton)

        contentView.stackView.addArrangedSubview(selectNetworkView)
        contentView.stackView.addArrangedSubview(contactNameField)
        contentView.stackView.addArrangedSubview(contactAddressField)

        navigationBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(UIConstants.bigOffset)
            make.bottom.equalTo(createButton.snp.top).offset(-UIConstants.bigOffset)
        }

        selectNetworkView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        contactNameField.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        contactAddressField.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        createButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.bottom.equalToSuperview().inset(UIConstants.bigOffset)
            make.height.equalTo(UIConstants.actionHeight)
        }
    }

    private func applyLocalization() {
        createButton.imageWithTitleView?.title = R.string.localizable.contactsCreateContact(
            preferredLanguages: locale.rLanguages
        )
        navigationBar.setTitle(R.string.localizable.contactsCreateContact(
            preferredLanguages: locale.rLanguages
        ))
        contactNameField.textField.placeholder = R.string.localizable.contactsContactName(
            preferredLanguages: locale.rLanguages
        )
        contactAddressField.textField.placeholder = R.string.localizable.contactsContactAddress(
            preferredLanguages: locale.rLanguages
        )
        selectNetworkView.title = R.string.localizable.commonSelectNetwork(preferredLanguages: locale.rLanguages)
    }
}
