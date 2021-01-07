import UIKit
import Kingfisher

class ProviderCell: UITableViewCell, ReusableCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let betaLabel = UILabel()
    private let stackView = UIStackView()
    private let titleStackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let iconSize: CGFloat = 40
    private let iconTitleSpacing: CGFloat = 16

    private func setup() {
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        backgroundColor = Color.background

        contentView.addSubview(iconView)
        contentView.addSubview(stackView)

        contentView.layoutMargins = .init(top: 32, left: 24, bottom: 32, right: 24)

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .horizontal
        titleStackView.spacing = 8
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(betaLabel)
        stackView.addArrangedSubview(titleStackView)
        stackView.addArrangedSubview(descriptionLabel)

        titleLabel.numberOfLines = 0
        titleLabel.font = Font.body1
        titleLabel.textColor = Color.label

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = Font.caption
        descriptionLabel.textColor = Color.secondaryLabel

        betaLabel.font = Font.caption
        betaLabel.textColor = Color.secondaryLabel
        betaLabel.text = "BETA"

        separatorInset.left = contentView.layoutMargins.left + iconSize + iconTitleSpacing
        separatorInset.right = contentView.layoutMargins.right

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -iconTitleSpacing),

            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.lastBaselineAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = ""
        descriptionLabel.text = ""
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()

        separatorInset.left = contentView.layoutMargins.left + iconSize + iconTitleSpacing
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        let applyHighlight = {
            self.backgroundColor = highlighted ? Color.accentBackground : Color.background
        }

        if animated {
            UIView.animate(withDuration: 0.15) {
                applyHighlight()
            }
        } else {
            applyHighlight()
        }
    }

    func setImage(url: URL) {
        iconView.kf.setImage(with: ImageResource(downloadURL: url))
    }

    func setTitle(text: String) {
        titleLabel.text = text
    }

    func setDescription(text: String) {
        descriptionLabel.text = text
    }

    func setBetaLabelHidden(_ hidden: Bool) {
        betaLabel.isHidden = hidden
    }
}
