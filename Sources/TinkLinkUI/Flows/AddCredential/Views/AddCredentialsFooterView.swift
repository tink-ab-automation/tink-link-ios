import UIKit
import TinkLink

protocol AddCredentialsFooterViewDelegate: AnyObject {
    func addCredentialsFooterViewDidTapLink(_ addCredentialsFooterView: AddCredentialsFooterView, url: URL)
    func addCredentialsFooterViewDidTapConsentReadMoreLink(_ addCredentialsFooterView: AddCredentialsFooterView)
}

final class AddCredentialsFooterView: UIView {
    weak var delegate: AddCredentialsFooterViewDelegate?

    private lazy var descriptionTextView: UITextView = {
        let descriptionTextView = UnselectableTextView()
        descriptionTextView.delegate = self
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.isEditable = false
        descriptionTextView.clipsToBounds = false
        descriptionTextView.backgroundColor = Color.background
        descriptionTextView.setLineHeight(lineHeight: 18)
        descriptionTextView.linkTextAttributes = [
            .foregroundColor: Color.secondaryLabel,
            .font: Font.caption,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = .zero
        return descriptionTextView
    }()

    private var privacyPolicyRange: NSRange?
    private var termsAndConditionsRange: NSRange?
    private var viewDetailsRange: NSRange?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(descriptionTextView)

        descriptionTextView.accessibilityIdentifier = "termsAndConsentText"

        layoutMargins = .init(top: 12, left: 0, bottom: 12, right: 0)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            descriptionTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    func configure(_ clientName: String) {
        let termsAndConsentFormat = Strings.Credentials.termsAndConsentText
        let termsAndConditions = Strings.Credentials.termsAndConditions
        let privacyPolicy = Strings.Credentials.privacyPolicy
        let viewDetails = Strings.Credentials.viewDetails
        let text = String(format: termsAndConsentFormat, termsAndConditions, privacyPolicy, clientName, viewDetails)
        let attributeText = NSMutableAttributedString(
            string: text,
            attributes: [.foregroundColor: Color.secondaryLabel, .font: Font.caption]
        )
        let languageCode = Locale.current.languageCode ?? ""
        let privacyPolicyUrl = URL(string: "https://link.tink.com/privacy-policy/\(languageCode)")!
        let privacyPolicyText = Strings.Credentials.privacyPolicy
        let privacyPolicyRange = attributeText.mutableString.range(of: privacyPolicyText)
        self.privacyPolicyRange = privacyPolicyRange
        attributeText.addAttributes([.link: privacyPolicyUrl], range: privacyPolicyRange)
        let termsAndConditionsText = Strings.Credentials.termsAndConditions
        let termsAndConditionsUrl = URL(string: "https://link.tink.com/terms-and-conditions/\(languageCode)")!
        let termsAndConditionsRange = attributeText.mutableString.range(of: termsAndConditionsText)
        self.termsAndConditionsRange = termsAndConditionsRange
        attributeText.addAttributes([.link: termsAndConditionsUrl], range: termsAndConditionsRange)

        let viewDetailsText = Strings.Credentials.viewDetails
        let viewDetailsRange = attributeText.mutableString.range(of: viewDetailsText)
        self.viewDetailsRange = viewDetailsRange
        attributeText.addAttributes([.link: ""], range: viewDetailsRange)

        descriptionTextView.attributedText = attributeText
        descriptionTextView.adjustsFontForContentSizeCategory = true
        descriptionTextView.setLineHeight(lineHeight: 18)
    }
}

extension AddCredentialsFooterView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            if characterRange == termsAndConditionsRange || characterRange == privacyPolicyRange {
                delegate?.addCredentialsFooterViewDidTapLink(self, url: URL)
                return false
            } else if characterRange == viewDetailsRange {
                delegate?.addCredentialsFooterViewDidTapConsentReadMoreLink(self)
                return false
            } else {
                return true
            }
        default:
            return true
        }
    }
}
