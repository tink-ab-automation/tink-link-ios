import UIKit

final class FloatingButton: UIControl {
    private enum Constants {
        static let insets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    }

    private let titleLabel = UILabel()
    private let contentView = UIView()
    private let imageView = UIImageView()
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageTrailingConstraint: NSLayoutConstraint?
    private var minimumWidthConstraint: NSLayoutConstraint?

    var minimumWidth: CGFloat = 150 {
        didSet {
            invalidateIntrinsicContentSize()
            minimumWidthConstraint?.constant = minimumWidth
            setNeedsLayout()
        }
    }

    var textColor: UIColor = Color.buttonLabel {
        didSet {
            titleLabel.textColor = textColor
            imageView.tintColor = textColor
        }
    }

    var rounded: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }

    var text: String? {
        set {
            accessibilityLabel = newValue
            titleLabel.text = newValue
        }
        get {
            return titleLabel.text
        }
    }

    var image: UIImage? {
        didSet {
            if let image = image {
                imageWidthConstraint?.constant = image.size.width + 4
                imageTrailingConstraint?.constant = 4
            } else {
                imageWidthConstraint?.constant = 0
                imageTrailingConstraint?.constant = 0
            }
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = rounded ? bounds.height / 2 : 0
    }

    override var isHighlighted: Bool {
        didSet {
            titleLabel.textColor = isHighlighted ? textColor.withAlphaComponent(0.5) : textColor
            imageView.tintColor = isHighlighted ? textColor.withAlphaComponent(0.5) : textColor
        }
    }

    override var isEnabled: Bool {
        didSet {
            titleLabel.alpha = isEnabled ? 1.0 : 0.2
            imageView.alpha = isEnabled ? 1.0 : 0.2
        }
    }

    override var intrinsicContentSize: CGSize {
        let titleLabelSize = titleLabel.intrinsicContentSize
        let imageWidth = imageWidthConstraint?.constant ?? 0
        return CGSize(width: max(minimumWidth, titleLabelSize.width + Constants.insets.left + Constants.insets.right + imageWidth),
                      height: 52)
    }

    private func setup() {
        backgroundColor = Color.button

        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = false
        addSubview(contentView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = Font.button
        titleLabel.textColor = Color.buttonLabel
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(titleLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = Color.buttonLabel
        imageView.contentMode = .center
        contentView.addSubview(imageView)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 7)
        layer.shadowRadius = 21

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)
        self.imageWidthConstraint = imageWidthConstraint

        let imageTrailingConstraint = titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 0)
        self.imageTrailingConstraint = imageTrailingConstraint

        let minimumWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth)
        self.minimumWidthConstraint = minimumWidthConstraint

        NSLayoutConstraint.activate([
            minimumWidthConstraint,
            imageWidthConstraint,
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageTrailingConstraint,
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
