@testable import TinkCore

extension Provider {
    static let nordeaBankID = Provider(
        name: "nordea-bankid",
        displayName: "Nordea",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .mobileBankID,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Nordea",
        image: nil,
        displayDescription: "Mobile BankID",
        capabilities: .init(rawValue: 1266),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "dde2463acf40501389de4fca5a3693a4", name: "Nordea")
    )

    static let nordeaPassword = Provider(
        name: "nordea-password",
        displayName: "Nordea",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .password,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Nordea",
        image: nil,
        displayDescription: "Password",
        capabilities: .init(rawValue: 1266),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "dde2463acf40501389de4fca5a3693a4", name: "Nordea")
    )

    static let nordeaOpenBanking = Provider(
        name: "se-nordea-ob",
        displayName: "Nordea Open Banking",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .mobileBankID,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Nordea",
        image: nil,
        displayDescription: "Mobile BankID",
        capabilities: .init(rawValue: 1266),
        accessType: .openBanking,
        marketCode: "SE",
        financialInstitution: .init(id: "dde2463acf40501389de4fca5a3693a4", name: "Nordea")
    )

    static let sparbankernaBankID = Provider(
        name: "savingsbank-bankid",
        displayName: "Sparbankerna",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .mobileBankID,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Swedbank och Sparbankerna",
        image: nil,
        displayDescription: "Mobile BankID",
        capabilities: .init(rawValue: 1534),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "a0afa9bbc85c52aba1b1b8d6a04bc57c", name: "Sparbankerna")
    )

    static let sparbankernaPassword = Provider(
        name: "savingsbank-token",
        displayName: "Sparbankerna",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .password,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Swedbank och Sparbankerna",
        image: nil,
        displayDescription: "Security token",
        capabilities: .init(rawValue: 1534),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "a0afa9bbc85c52aba1b1b8d6a04bc57c", name: "Sparbankerna")
    )

    static let swedbankBankID = Provider(
        name: "swedbank-bankid",
        displayName: "Swedbank",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .mobileBankID,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Swedbank och Sparbankerna",
        image: nil,
        displayDescription: "Mobile BankID",
        capabilities: .init(rawValue: 1534),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "6c1749b4475e5677a83e9fa4bb60a18a", name: "Swedbank")
    )

    static let swedbankPassword = Provider(
        name: "swedbank-token",
        displayName: "Swedbank",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .password,
        helpText: "",
        isPopular: true,
        fields: [],
        groupDisplayName: "Swedbank och Sparbankerna",
        image: nil,
        displayDescription: "Security token",
        capabilities: .init(rawValue: 1534),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "6c1749b4475e5677a83e9fa4bb60a18a", name: "Swedbank")
    )

    static let testSupplementalInformation = Provider(
        name: "se-test-multi-supplemental",
        displayName: "Test Multi-Supplemental",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .test,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .password,
        helpText: "Use the same username and password as you would in the bank\'s mobile app.",
        isPopular: true,
        fields: [Field(description: "Username", hint: "", maxLength: nil, minLength: nil, isMasked: false, isNumeric: false, isImmutable: false, isOptional: false, name: "username", initialValue: "", pattern: "", patternError: "", helpText: "", selectOptions: [])],
        groupDisplayName: "Test Multi-Supplemental",
        image: nil,
        displayDescription: "Password",
        capabilities: .init(rawValue: 1276),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "3590cce61e1256dd9cb2c32bfacb713b", name: "Test Multi-Supplemental")
    )

    static let testThirdPartyAuthentication = Provider(
        name: "se-test-multi-third-party",
        displayName: "Test Third Party Authentication",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .test,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .thirdPartyAuthentication,
        helpText: "Use the same username and password as you would in the bank\'s mobile app.",
        isPopular: true,
        fields: [],
        groupDisplayName: "Test Third Party Authentication",
        image: nil,
        displayDescription: "Test",
        capabilities: .init(rawValue: 1276),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "3590cce61e1256dd9cb2c32bfacb713b", name: "Test Multi-Supplemental")
    )

    static let testPassword = Provider(
        name: "se-test-password",
        displayName: "Test Password",
        financialServices: [Provider.FinancialService(segment: .personal, shortName: "")],
        kind: .bank,
        releaseStatus: nil,
        status: .enabled,
        credentialsKind: .password,
        helpText: "",
        isPopular: true,
        fields: [Field(description: "Username", hint: "", maxLength: nil, minLength: nil, isMasked: false, isNumeric: false, isImmutable: false, isOptional: false, name: "username", initialValue: "", pattern: "", patternError: "", helpText: "", selectOptions: [])],
        groupDisplayName: "Test Password",
        image: nil,
        displayDescription: "Password",
        capabilities: .init(rawValue: 1266),
        accessType: .other,
        marketCode: "SE",
        financialInstitution: .init(id: "4d0c65519a5e5a0d80e218a92f9ae1d6", name: "Test Password")
    )
}
