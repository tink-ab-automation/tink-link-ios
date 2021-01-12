import UIKit

protocol AddCredentialsStatusViewControllerDelegate: AnyObject {
    func addCredentialsStatusViewControllerDidCancel(_ viewController: AddCredentialsStatusViewController)
}

final class AddCredentialsStatusViewController: UIViewController {
    private lazy var activityIndicator = ActivityIndicatorView()
    private lazy var statusLabelView = UILabel()
    private lazy var cancelButton = UIButton(type: .system)

    weak var delegate: AddCredentialsStatusViewControllerDelegate?

    var status: String? {
        get {
            guard isViewLoaded else { return nil }
            return statusLabelView.text
        }
        set {
            guard isViewLoaded else { return }
            statusLabelView.text = newValue
            presentationController?.containerView?.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentStackView = UIStackView(arrangedSubviews: [activityIndicator, statusLabelView])
        contentStackView.axis = .vertical
        contentStackView.isLayoutMarginsRelativeArrangement = true
        contentStackView.layoutMargins = UIEdgeInsets(top: 32, left: 24, bottom: 24, right: 24)
        contentStackView.spacing = 16

        let dividerView = UIView()
        dividerView.backgroundColor = Color.separator

        let stackView = UIStackView(arrangedSubviews: [contentStackView, dividerView, cancelButton])
        stackView.axis = .vertical
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        statusLabelView.font = Font.subtitle1
        statusLabelView.textColor = Color.label
        statusLabelView.numberOfLines = 0
        statusLabelView.preferredMaxLayoutWidth = 220
        statusLabelView.textAlignment = .center

        activityIndicator.tintColor = Color.accent
        activityIndicator.startAnimating()
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .vertical)

        cancelButton.setTitle(Strings.Generic.cancel, for: .normal)
        cancelButton.titleLabel?.font = Font.button
        cancelButton.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
        cancelButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        cancelButton.tintColor = Color.button

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    @objc private func cancel(_ sender: Any) {
        delegate?.addCredentialsStatusViewControllerDidCancel(self)
    }
}
