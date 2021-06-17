import Foundation
import TinkLink

extension TinkLinkError: LocalizedError {
    public var errorDescription: String? {
        switch code {
        case .credentialsAuthenticationFailed:
            return "Authentication Failed"
        case .credentialsAlreadyExists:
            return "Credentials Already Exists"
        case .permanentCredentialsFailure:
            return "Permanent Failure"
        case .temporaryCredentialsFailure:
            return "Temporary Failure"
        case .credentialsDeleted:
            return "Deleted"
        case .cancelled:
            return "Cancelled"
        case .thirdPartyAppAuthenticationFailed:
            return thirdPartyAppAuthenticationFailureReason?.errorDescription
        default:
            return "Error"
        }
    }

    public var failureReason: String? {
        switch self {
        case .credentialsAuthenticationFailed,
             .credentialsAlreadyExists,
             .permanentCredentialsFailure,
             .temporaryCredentialsFailure,
             .credentialsDeleted:
            return message
        case .thirdPartyAppAuthenticationFailed:
            return thirdPartyAppAuthenticationFailureReason?.failureReason
        default:
            return nil
        }
    }
}

extension TinkLinkError.ThirdPartyAppAuthenticationFailureReason: LocalizedError {
    public var errorDescription: String? {
        switch code {
        case .deeplinkURLNotFound:
            return nil
        case .downloadRequired:
            return downloadTitle
        case .doesNotSupportAuthenticatingOnAnotherDevice:
            return "This bank does not support authenticating on another device."
        case .decodingQRCodeImageFailed:
            return "Failed to decode the QR code image."
        default:
            return "Error"
        }
    }

    public var failureReason: String? {
        switch code {
        case .deeplinkURLNotFound:
            return nil
        case .downloadRequired:
            return downloadMessage
        case .doesNotSupportAuthenticatingOnAnotherDevice:
            return nil
        case .decodingQRCodeImageFailed:
            return nil
        default:
            return nil
        }
    }
}
