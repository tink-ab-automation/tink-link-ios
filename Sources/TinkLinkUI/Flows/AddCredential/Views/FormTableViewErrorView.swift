import UIKit

final class FormTableViewErrorView: UIView {
    private let contentView = UIView()
    private let errorLabel = UILabel()

    init(errorText: String) {
        super.init(frame: .zero)
        errorLabel.text = errorText
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = Color.background
        layoutMargins = UIDevice.current.isPad ? .init(top: 0, left: 80, bottom: 12, right: 80) : .init(top: 0, left: 24, bottom: 12, right: 24)

        contentView.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Color.critical.cgColor
        contentView.layer.cornerRadius = 4

        errorLabel.textColor = Color.critical
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        errorLabel.font = Font.body2
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.setLineHeight(lineHeight: 20)

        addSubview(contentView)
        contentView.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            errorLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            errorLabel.lastBaselineAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
