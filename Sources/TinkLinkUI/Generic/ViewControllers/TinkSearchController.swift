import UIKit

final class TinkSearchController: UISearchController {
    private lazy var tinkSearchBar = TinkSearchBar()

    override var searchBar: UISearchBar { tinkSearchBar }
}

private final class TinkSearchBar: UISearchBar {
    var textField: UITextField? {
        if #available(iOS 13.0, *) {
            return searchTextField
        } else {
            return subviews.first?.subviews.first { $0 is UITextField } as? UITextField
        }
    }

    override var placeholder: String? {
        didSet {
            // Hack: You need the async call here to have the color apply properly.
            DispatchQueue.main.async {
                self.textField?.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [.foregroundColor: Color.secondaryLabel, .font: Font.body1])
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        if #available(iOS 13.0, *) {
            let attributes = [
                NSAttributedString.Key.foregroundColor: Color.navigationBarButton,
                NSAttributedString.Key.font: Font.body1
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [TinkSearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
        } else {
            tintColor = Color.navigationBarButton
        }

        if let imageView = textField?.leftView as? UIImageView {
            imageView.tintColor = Color.secondaryLabel
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        }
        textField?.backgroundColor = Color.accent.mixedWith(color: Color.navigationBarBackground, factor: 0.95)
        textField?.textColor = Color.navigationBarLabel
        textField?.font = Font.body1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textField?.textColor = Color.navigationBarLabel
    }
}
