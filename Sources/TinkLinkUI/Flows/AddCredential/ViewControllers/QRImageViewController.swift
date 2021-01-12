import UIKit

protocol QRImageViewControllerDelegate: AnyObject {
    func qrImageViewControllerDidCancel(_ viewController: QRImageViewController)
}

final class QRImageViewController: UIViewController {
    private let imageContainerView = UIView()
    private let borderedCornersView = BorderedCornersView()
    private let imageView = UIImageView()
    private let subtitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let stackView = UIStackView()

    weak var delegate: QRImageViewControllerDelegate?

    init(qrImage: UIImage) {
        if let image = qrImage.cgImage?.withMaskedWhiteChannel {
            imageView.image = UIImage(cgImage: image).withRenderingMode(.alwaysTemplate)
        } else {
            imageView.image = qrImage
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        navigationItem.title = Strings.SupplementalInformation.title
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))

        view.backgroundColor = Color.background

        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.translatesAutoresizingMaskIntoConstraints = false
        borderedCornersView.tintColor = Color.accent
        borderedCornersView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = Font.subtitle1
        subtitleLabel.textColor = Color.label
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = Strings.SupplementalInformation.qrCodeTitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = Font.caption
        descriptionLabel.textColor = Color.label
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = Strings.SupplementalInformation.qrCodeDescription
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        stackView.addArrangedSubview(imageContainerView)
        stackView.setCustomSpacing(32, after: imageContainerView)
        imageContainerView.addSubview(imageView)
        imageContainerView.addSubview(borderedCornersView)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 172),
            imageView.widthAnchor.constraint(equalToConstant: 172),
            imageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            borderedCornersView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            borderedCornersView.topAnchor.constraint(equalTo: imageView.topAnchor),
            borderedCornersView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            borderedCornersView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)
        ])
    }

    @objc private func cancelButtonPressed() {
        delegate?.qrImageViewControllerDidCancel(self)
    }
}
