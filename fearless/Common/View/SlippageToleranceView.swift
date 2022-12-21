import UIKit
import SoraUI
import FearlessUtils

final class SlippageToleranceView: UIView {
    enum LayoutConstants {
        static let iconSize = CGSize(width: 26, height: 24)
        static let viewHeight: CGFloat = 64
        static let verticalOffset: CGFloat = 12
    }

    private let backgroundView: TriangularedView = {
        let view = TriangularedView()
        view.fillColor = R.color.colorSemiBlack()!
        view.highlightedFillColor = R.color.colorSemiBlack()!
        view.strokeColor = R.color.colorWhite8()!
        view.highlightedStrokeColor = R.color.colorPink()!
        view.strokeWidth = 0.5
        view.shadowOpacity = 0
        return view
    }()

    private let attensionImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .h5Title
        label.textColor = R.color.colorStrokeGray()
        return label
    }()

    let textField: UITextField = {
        let view = UITextField()
        view.tintColor = R.color.colorPink()
        view.font = .p1Paragraph
        view.textColor = R.color.colorWhite()
        view.keyboardType = .decimalPad
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(with viewModel: SlippageToleranceViewModel) {
        attensionImageView.isHidden = viewModel.image == nil
        attensionImageView.image = viewModel.image
        textField.attributedText = viewModel.attributedText
    }

    func set(highlighted: Bool, animated: Bool) {
        backgroundView.set(highlighted: highlighted, animated: animated)
    }

    private func setupLayout() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(LayoutConstants.viewHeight)
        }

        let hStackView = UIFactory.default.createHorizontalStackView(spacing: UIConstants.defaultOffset)
        hStackView.distribution = .fillProportionally
        hStackView.alignment = .center
        backgroundView.addSubview(hStackView)
        hStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIConstants.bigOffset)
        }

        hStackView.addArrangedSubview(attensionImageView)
        attensionImageView.snp.makeConstraints { make in
            make.size.equalTo(LayoutConstants.iconSize)
        }

        let vTextStackView = UIFactory.default.createVerticalStackView(spacing: UIConstants.minimalOffset)
        hStackView.addArrangedSubview(vTextStackView)

        vTextStackView.addArrangedSubview(titleLabel)
        vTextStackView.addArrangedSubview(textField)
    }
}

struct SlippageToleranceViewModel {
    let value: Float
    let attributedText: NSAttributedString
    let image: UIImage?
}
