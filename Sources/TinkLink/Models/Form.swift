import Foundation

/// A `Form` is used to determine what a user needs to input in order to proceed when creating or updating a credentials. For example it could be a username and a password field.
///
/// Here's how to create a form for a provider with a username and password field and how to update the fields.
///
/// ```swift
/// var form = Form(provider: <#Provider#>)
/// form.fields[name: "username"]?.text = <#String#>
/// form.fields[name: "password"]?.text = <#String#>
/// ...
/// ```
///
/// ### Configuring UITextFields from form fields
///
/// The `Field` within a `Form` contains attributes that map well to `UITextField`.
///
/// ```swift
/// for field in form.fields {
///     let textField = UITextField()
///     textField.placeholder = field.attributes.placeholder
///     textField.isSecureTextEntry = field.attributes.isSecureTextEntry
///     textField.isEnabled = field.attributes.isEditable
///     textField.text = field.text
///     <#Add to view#>
/// }
/// ```
/// ### Form validation
///
/// Validate before you submit a request to add credentials or supplement information.
///
/// Use `areFieldsValid` to check if all form fields are valid. For example, you can use this to enable a submit button when text fields change.
///
/// ```swift
/// @objc func textFieldDidChange(_ notification: Notification) {
///     submitButton.isEnabled = form.areFieldsValid
/// }
/// ```
///
/// Use validateFields() to validate all fields. If not valid, it will throw an error that contains more information about which fields are not valid and why.
///
/// ```swift
/// do {
///     try form.validateFields()
/// } catch let error as Form.Fields.ValidationError {
///     if let usernameFieldError = error[fieldName: "username"] {
///         usernameValidationErrorLabel.text = usernameFieldError.errorDescription
///     }
/// }
/// ```
public struct Form {
    /// A collection of fields.
    ///
    /// Represents a list of fields and provides access to the fields. Each field in can be accessed either by index or by field name.
    public struct Fields: MutableCollection, RandomAccessCollection {
        var fields: [Form.Field]

        // MARK: Collection Conformance

        public var startIndex: Int { fields.startIndex }
        public var endIndex: Int { fields.endIndex }
        public subscript(position: Int) -> Form.Field {
            get { fields[position] }
            set { fields[position] = newValue }
        }

        public func index(after i: Int) -> Int { fields.index(after: i) }

        // MARK: Dictionary Lookup

        /// Accesses the field associated with the given field for reading and writing.
        ///
        /// This name based subscript returns the first field with the same name, or `nil` if the field is not found.
        ///
        /// - Parameter name: The name of the field to find in the list.
        /// - Returns: The field associated with `name` if it exists; otherwise, `nil`.
        public subscript(name fieldName: String) -> Form.Field? {
            get {
                return fields.first(where: { $0.name == fieldName })
            }
            set {
                if let index = fields.firstIndex(where: { $0.name == fieldName }) {
                    if let field = newValue {
                        fields[index] = field
                    } else {
                        fields.remove(at: index)
                    }
                } else if let field = newValue {
                    fields.append(field)
                }
            }
        }
    }

    /// The fields associated with this form.
    public var fields: Fields

    internal init(fields: [Provider.Field]) {
        self.fields = Fields(fields: fields.map { Field(field: $0) })
    }

    /// Returns a Boolean value indicating whether every field in the form are valid.
    ///
    /// - Returns: `true` if all fields in the form have valid text; otherwise, `false`.
    public var areFieldsValid: Bool {
        return fields.areFieldsValid
    }

    /// Validate all fields.
    ///
    /// Use this method to validate all fields in the form or catch the value if one or more field are invalid.
    ///
    /// - Returns: `true` if all fields in the form have valid text; otherwise, `false`.
    /// - Throws: A `Form.ValidationError` if one or more fields are invalid.
    public func validateFields() throws {
        try fields.validateFields()
    }

    internal func makeFields() -> [String: String] {
        var fieldValues: [String: String] = [:]
        for field in fields {
            fieldValues[field.name] = field.text
        }
        return fieldValues
    }

    /// A `Field` represent one specific input (usually a text field) that the user need to enter in order to add a credential.
    public struct Field {
        /// The current text input of the field. Update this to reflect the user's input.
        public var text: String
        /// The name of the field.
        public let name: String
        /// The validation rules that determines whether the `text` property is valid.
        public let validationRules: ValidationRules
        /// The attributes of the field.
        ///
        /// You can use the attributes to set up a text field properly. They contain properties
        /// like input type, placeholder and description.
        public internal(set) var attributes: Attributes

        /// Validation rules for a field.
        ///
        /// Represents the rules for validating a form field.
        public struct ValidationRules {
            /// If `true` the field is not required to have text for the field to be valid.
            public let isOptional: Bool

            /// Maximum length of value.
            ///
            /// Use this to e.g. limit user input to only accept input until `maxLength` is reached.
            public let maxLength: Int?

            /// Minimum length of value.
            public let minLength: Int?

            internal let regex: String?
            internal let regexError: String?

            internal func validate(_ value: String, fieldName name: String) throws {
                if value.isEmpty, !isOptional {
                    throw ValidationError.requiredFieldEmptyValue(fieldName: name)
                } else if let maxLength = maxLength, maxLength > 0 && maxLength < value.count {
                    throw ValidationError.maxLengthLimit(fieldName: name, maxLength: maxLength)
                } else if let minLength = minLength, minLength > 0 && minLength > value.count {
                    throw ValidationError.minLengthLimit(fieldName: name, minLength: minLength)
                } else if let unwrappedRegex = regex, !unwrappedRegex.isEmpty, let regex = try? NSRegularExpression(pattern: unwrappedRegex, options: []) {
                    let range = regex.rangeOfFirstMatch(in: value, options: [], range: NSRange(location: 0, length: value.count))
                    if range.location == NSNotFound {
                        throw ValidationError.invalid(fieldName: name, reason: regexError ?? "")
                    }
                }
            }
        }

        /// Attributes to apply to a UI element that will represent a field.
        public struct Attributes {
            /// Input type for a field.
            ///
            /// Represents the different input types a field can have.
            public struct InputType: Equatable, CustomStringConvertible {
                private enum Value {
                    case `default`
                    case numeric
                }

                private var value: Value

                public var description: String {
                    return "Form.Field.Attributes.InputType.\(value)"
                }

                /// An input type suitable for normal text input.
                public static let `default` = Self(value: .default)
                /// An input type suitable for e.g. PIN entry.
                public static let numeric = Self(value: .numeric)
            }

            /// A string to display next to the field to explain what the field is for.
            public let description: String

            /// A string to display when there is no other text in the text field.
            public let placeholder: String?

            /// A string to display next to the field with information about what the user should enter in the text field.
            public let helpText: String?

            /// Identifies whether the text object should hide the text being entered.
            public let isSecureTextEntry: Bool

            /// The input type associated with the field.
            public let inputType: InputType

            /// A Boolean value indicating whether the field can be edited.
            public internal(set) var isEditable: Bool
        }

        /// Describes a field validation error.
        public struct ValidationError: Error, CustomStringConvertible {
            public struct Code: Hashable {
                enum Value {
                    case invalid
                    case maxLengthLimit
                    case minLengthLimit
                    case requiredFieldEmptyValue
                }

                var value: Value

                public static let invalid = Self(value: .invalid)
                public static let maxLengthLimit = Self(value: .maxLengthLimit)
                public static let minLengthLimit = Self(value: .minLengthLimit)
                public static let requiredFieldEmptyValue = Self(value: .requiredFieldEmptyValue)

                public static func ~= (lhs: Self, rhs: Swift.Error) -> Bool {
                    lhs == (rhs as? Form.Field.ValidationError)?.code
                }
            }

            public let code: Code

            public var description: String {
                return "Form.Field.ValidationError.Error.\(code.value))"
            }

            /// Field's `text` was invalid. See `reason` for explanation why.
            public static let invalid: Code = .invalid

            /// Field's `text` was too long.
            public static let maxLengthLimit: Code = .maxLengthLimit

            /// Field's `text` was too short.
            public static let minLengthLimit: Code = .minLengthLimit

            /// Missing `text` for required field.
            public static let requiredFieldEmptyValue: Code = .requiredFieldEmptyValue

            public var fieldName: String

            /// An error message describing what is the reason for the invalid validation failure.
            public var reason: String?

            public var minLength: Int?
            public var maxLength: Int?

            static func invalid(fieldName: String, reason: String) -> Self {
                .init(code: .invalid, fieldName: fieldName, reason: reason)
            }

            static func maxLengthLimit(fieldName: String, maxLength: Int) -> Self {
                .init(code: .maxLengthLimit, fieldName: fieldName, maxLength: maxLength)
            }

            static func minLengthLimit(fieldName: String, minLength: Int) -> Self {
                .init(code: .minLengthLimit, fieldName: fieldName, minLength: minLength)
            }

            static func requiredFieldEmptyValue(fieldName: String) -> Self {
                .init(code: .requiredFieldEmptyValue, fieldName: fieldName)
            }
        }

        /// Returns a Boolean value indicating whether the field is valid.
        ///
        /// To check why `text` wasn't valid if `false`, call `validate()` and check the thrown error for validation failure reason.
        ///
        /// - Returns: `true` if the field pass the validation rules; otherwise, `false`.
        public var isValid: Bool {
            do {
                try validate()
                return true
            } catch {
                return false
            }
        }

        /// Validate field.
        ///
        /// Use this method to validate the current `text` value of the field or to catch the value if invalid.
        ///
        /// - Throws: A `Form.Field.ValidationError` if the field's `text` is invalid.
        public func validate() throws {
            let value = text
            try validationRules.validate(value, fieldName: name)
        }
    }

    /// Describes a form validation error.
    public struct ValidationError: Error {
        /// Describes one or more field validation errors.
        public var errors: [Form.Field.ValidationError]

        /// Accesses the validation error associated with the given field.
        ///
        /// This name based subscript returns the first error with the same name, or `nil` if an error is not found.
        ///
        /// - Parameter fieldName: The name of the field to find an error for.
        /// - Returns: The validation error associated with `fieldName` if it exists; otherwise, `nil`.
        public subscript(fieldName fieldName: String) -> Form.Field.ValidationError? {
            errors.first(where: { $0.fieldName == fieldName })
        }
    }
}

extension Form {
    /// Creates a form for the given provider.
    ///
    /// This creates a form to use for creating a credentials for a specific provider.
    ///
    /// - Parameter provider: The provider to create a form for.
    public init(provider: Provider) {
        self.init(fields: provider.fields)
    }

    /// Creates a form for the given credentials.
    ///
    /// This creates a form to use for supplementing information for a credentials.
    ///
    /// - Parameter credential: The credentials to create a form for.
    @available(*, deprecated, message: "Use init(supplementInformationTask:) instead.")
    public init(credentials: Credentials) {
        if case .awaitingSupplementalInformation(let fields) = credentials.status {
            self.init(fields: fields)
        } else {
            self.init(fields: [])
        }
    }

    /// Creates a form for updating the given credentials.
    ///
    /// - Parameters:
    ///   - updatingCredentials: The credentials to update.
    ///   - provider: The provider for the credentials to update.
    public init(updatingCredentials: Credentials, provider: Provider) {
        var providerForm = Form(fields: provider.fields)
        for (name, value) in updatingCredentials.fields {
            providerForm.fields[name: name]?.text = value
            providerForm.fields[name: name]?.attributes.isEditable = false
        }
        self = providerForm
    }

    /// Creates a form for the given task.
    ///
    /// This creates a form to use for supplementing information.
    ///
    /// - Parameter supplementInformationTask: The supplemental information task to create a form for.
    public init(supplementInformationTask: SupplementInformationTask) {
        if case .awaitingSupplementalInformation(let fields) = supplementInformationTask.credentials.status {
            self.init(fields: fields)
        } else {
            self.init(fields: [])
        }
    }
}

extension Form.Fields {
    /// Validate fields.
    ///
    /// Use this method to validate all fields. If any field is not valid, it will throw an error that contains
    /// more information about which fields are not valid and why.
    ///
    /// ```swift
    /// do {
    ///     try form.validateFields()
    /// } catch let error as Form.Fields.ValidationError {
    ///     if let usernameFieldError = error[fieldName: "username"] {
    ///         usernameValidationErrorLabel.text = usernameFieldError.errorDescription
    ///     }
    /// }
    /// ```
    ///
    /// - Throws: A `Form.ValidationError` if any of the fields' `text` value is invalid.
    func validateFields() throws {
        var fieldsValidationError = Form.ValidationError(errors: [])
        for field in fields {
            do {
                try field.validate()
            } catch let error as Form.Field.ValidationError {
                fieldsValidationError.errors.append(error)
            } catch {
                fatalError()
            }
        }
        guard fieldsValidationError.errors.isEmpty else { throw fieldsValidationError }
    }

    /// A Boolean value indicating whether all fields have valid values.
    ///
    /// Use `areFieldsValid` to check if all form fields are valid. For example, you can use this to enable a submit button when text fields change.
    ///
    /// ```swift
    /// @objc func textFieldDidChange(_ notification: Notification) {
    ///     submitButton.isEnabled = form.areFieldsValid
    /// }
    /// ```
    ///
    /// - Returns: `true` if all fields in the form have valid text; otherwise, `false`.
    var areFieldsValid: Bool {
        do {
            try validateFields()
            return true
        } catch {
            return false
        }
    }
}

extension Form.Field {
    internal init(field fieldSpecification: Provider.Field) {
        self.text = fieldSpecification.initialValue
        self.name = fieldSpecification.name
        self.validationRules = ValidationRules(
            isOptional: fieldSpecification.isOptional,
            maxLength: fieldSpecification.maxLength,
            minLength: fieldSpecification.minLength,
            regex: fieldSpecification.pattern,
            regexError: fieldSpecification.patternError
        )
        self.attributes = Attributes(
            description: fieldSpecification.description ?? "",
            placeholder: fieldSpecification.hint,
            helpText: fieldSpecification.helpText,
            isSecureTextEntry: fieldSpecification.isMasked,
            inputType: fieldSpecification.isNumeric ? .numeric : .default,
            isEditable: !fieldSpecification.isImmutable || (fieldSpecification.initialValue).isEmpty
        )
    }
}
