import UIKit

class FloatingPlaceholderTextField: UITextField {
    private enum Constants {
        static let placeholderTextSize: CGFloat = 13.0
        static let editableTextHeightPadding: CGFloat = 8.0
        static let uneditableTextHeightPadding: CGFloat = 16.0
    }

    enum InputType {
        case text
        case number
    }

    var inputType: InputType = .text {
        didSet {
            updateInputType()
        }
    }

    private var textFieldBackgroundColor: UIColor? {
        didSet {
            textFieldBackgroundColorLayer.backgroundColor = textFieldBackgroundColor?.cgColor
        }
    }

    private let underlineLayer = CAShapeLayer()
    private let placeholderLayer = CATextLayer()
    private let textFieldBackgroundColorLayer = CALayer()
    override var placeholder: String? {
        didSet {
            placeholderLayer.string = placeholder
        }
    }

    var lineWidth: CGFloat = 1.0 {
        didSet {
            underlineLayer.lineWidth = lineWidth
        }
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                textFieldBackgroundColor = nil
                textAlignment = .natural
                lineWidth = 1.0
            } else {
                textFieldBackgroundColor = Color.accentBackground
                textAlignment = .center
                lineWidth = 0.0
            }
            invalidateIntrinsicContentSize()
        }
    }

    override var text: String? {
        didSet {
            updatePlaceholderLayer()
        }
    }

    override var font: UIFont? {
        didSet {
            placeholderLayer.font = font as CFTypeRef
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

    override func drawPlaceholder(in rect: CGRect) {
        if placeholderLayer.frame.isEmpty {
            placeholderLayer.frame = rect
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textFieldBackgroundColorLayer.frame = CGRect(x: 0, y: Constants.placeholderTextSize / 2, width: bounds.width, height: bounds.height - Constants.placeholderTextSize)
        placeholderLayer.frame = placeholderRect(forBounds: bounds)

        underlineLayer.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: lineWidth)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: underlineLayer.bounds.midY))
        path.addLine(to: CGPoint(x: underlineLayer.bounds.maxX, y: underlineLayer.bounds.midY))
        underlineLayer.path = path.cgPath
        updatePlaceholderLayer()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            underlineLayer.strokeStart = 0.0
            underlineLayer.strokeEnd = 1.0
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            underlineLayer.strokeStart = 0.5
            underlineLayer.strokeEnd = 0.5
        }
        return result
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = size.height.rounded()
        if !isEnabled {
            size.height += Constants.placeholderTextSize + Constants.uneditableTextHeightPadding * 2
        } else {
            size.height += Constants.editableTextHeightPadding * 2
        }
        return size
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        underlineLayer.strokeColor = tintColor.cgColor
        placeholderLayer.foregroundColor = Color.secondaryLabel.cgColor
        underlineLayer.backgroundColor = Color.secondaryLabel.withAlphaComponent(0.5).cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }
            underlineLayer.strokeColor = tintColor.cgColor
            placeholderLayer.foregroundColor = Color.secondaryLabel.cgColor
            underlineLayer.backgroundColor = Color.secondaryLabel.withAlphaComponent(0.5).cgColor
        }
    }
}

extension FloatingPlaceholderTextField {
    private func setup() {
        clipsToBounds = false
        backgroundColor = .clear

        font = Font.body1
        textColor = Color.label
        layer.addSublayer(textFieldBackgroundColorLayer)

        placeholderLayer.font = font as CFTypeRef
        placeholderLayer.contentsScale = UIScreen.main.scale
        placeholderLayer.string = placeholder
        placeholderLayer.foregroundColor = Color.secondaryLabel.cgColor
        placeholderLayer.anchorPoint = .zero
        layer.addSublayer(placeholderLayer)

        underlineLayer.backgroundColor = Color.secondaryLabel.withAlphaComponent(0.5).cgColor
        underlineLayer.lineWidth = lineWidth
        underlineLayer.fillColor = UIColor.clear.cgColor
        underlineLayer.strokeColor = tintColor.cgColor
        underlineLayer.strokeEnd = 0.5
        underlineLayer.strokeStart = 0.5
        layer.addSublayer(underlineLayer)

        updateInputType()

        addTarget(self, action: #selector(didChangeText(_:)), for: .editingChanged)
    }

    @objc
    private func didChangeText(_ sender: Any) {
        updatePlaceholderLayer()
    }

    private func updatePlaceholderLayer() {
        guard let font = font,
              !placeholderLayer.frame.isEmpty else { return }

        let value = text ?? ""
        let placeholderUpTop = !value.isEmpty
        let targetSize: CGFloat = placeholderUpTop ? Constants.placeholderTextSize : font.pointSize

        placeholderLayer.fontSize = targetSize

        let placeholderFrame = placeholderRect(forBounds: bounds)
        placeholderLayer.position.x = placeholderUpTop ? 0 : placeholderLayer.frame.origin.x
        placeholderLayer.position.y = placeholderUpTop ? -targetSize : placeholderFrame.origin.y
    }

    private func updateInputType() {
        switch inputType {
        case .text:
            keyboardType = .default
        case .number:
            keyboardType = .numberPad
        }
    }
}
