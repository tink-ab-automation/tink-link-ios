import Foundation

extension Beneficiary {
    init(restBeneficiary beneficiary: RESTBeneficiary) {
        self.accountID = Account.ID(stringLiteral: beneficiary.accountId)
        self.accountNumber = beneficiary.accountNumber
        self.name = beneficiary.name
        if let encodedName = beneficiary.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            self.uri = URL(string: "\(beneficiary.type)://\(beneficiary.accountNumber)?name=\(encodedName)")
        } else {
            self.uri = nil
        }
    }
}
