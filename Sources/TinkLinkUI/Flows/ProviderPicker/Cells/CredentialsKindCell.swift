import UIKit

class CredentialsKindCell: UITableViewCell, ReusableCell {
    private let iconBackgroundView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let betaLabel = BetaTagView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let iconBackgroundSize: CGFloat = 40
    private let iconSize: CGFloat = 24
    private let iconTitleSpacing: CGFloat = 16

    private var trailingTitleConstraint: NSLayoutConstraint!
    private var trailingBetaConstraint: NSLayoutConstraint!

    private func setup() {
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        backgroundColor = Color.background

        contentView.addSubview(iconBackgroundView)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(betaLabel)

        contentView.layoutMargins = .init(top: 32, left: 24, bottom: 32, right: 24)

        iconBackgroundView.backgroundColor = Color.accent
        iconBackgroundView.clipsToBounds = true
        iconBackgroundView.layer.cornerRadius = iconBackgroundSize / 2
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Color.background
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = Font.body1
        titleLabel.textColor = Color.label

        betaLabel.translatesAutoresizingMaskIntoConstraints = false
        betaLabel.isHidden = true

        separatorInset.left = contentView.layoutMargins.left + iconSize + iconTitleSpacing
        separatorInset.right = contentView.layoutMargins.right

        trailingTitleConstraint = contentView.layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor)
        trailingBetaConstraint = contentView.layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: betaLabel.trailingAnchor)

        NSLayoutConstraint.activate([
            iconBackgroundView.widthAnchor.constraint(equalToConstant: iconBackgroundSize),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: iconBackgroundSize),
            iconBackgroundView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconBackgroundView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconBackgroundView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconBackgroundView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -iconTitleSpacing),

            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.lastBaselineAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            trailingTitleConstraint,

            betaLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            betaLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = ""
        setBetaLabelHidden(true)
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()

        separatorInset.left = contentView.layoutMargins.left + iconBackgroundSize + iconTitleSpacing
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

    func setIcon(_ icon: Icon) {
        iconView.image = UIImage(icon: icon)?.withRenderingMode(.alwaysTemplate)
    }

    func setTitle(text: String) {
        titleLabel.text = text
    }

    func setBetaLabelHidden(_ hidden: Bool) {
        betaLabel.isHidden = hidden
        trailingTitleConstraint.isActive = hidden
        trailingBetaConstraint.isActive = !hidden
    }
}
