@testable import TinkCore
@testable import TinkLink
import XCTest

class SupplementalInfoFieldTests: XCTestCase {
    func testSupplementalInfoFieldValidation() {
        let firstFieldSpecification = Provider.Field(
            description: "Security Code",
            hint: "",
            maxLength: nil,
            minLength: nil,
            isMasked: false,
            isNumeric: true,
            isImmutable: true,
            isOptional: false,
            name: "loginDescriptionField",
            initialValue: "7483",
            pattern: "",
            patternError: "",
            helpText: "Login using your Card Reader. Enter the security code and press Ok. Provide the given return code in the input field to continue \n",
            selectOptions: []
        )
        let secondFieldSpecification = Provider.Field(
            description: "Input Code",
            hint: "",
            maxLength: nil,
            minLength: nil,
            isMasked: false,
            isNumeric: true,
            isImmutable: false,
            isOptional: false,
            name: "loginInputField",
            initialValue: "7483",
            pattern: "",
            patternError: "",
            helpText: "",
            selectOptions: []
        )
        let supplementalInfoCredential = Credentials(id: .init(stringLiteral: "test-credential"), providerName: "test-multi-supplemental", kind: .password, status: .awaitingSupplementalInformation([firstFieldSpecification, secondFieldSpecification]), statusPayload: "", statusUpdated: nil, updated: nil, fields: ["username": "tink-test"], sessionExpiryDate: nil)

        var form = Form(credentials: supplementalInfoCredential)

        let editableForms = form.fields.filter { $0.attributes.isEditable }
        XCTAssertEqual(editableForms.count, 1)

        let edtiableForm = editableForms.first!
        do {
            try form.validateFields()
        } catch let error as Form.ValidationError {
            XCTAssertEqual(error.errors.count, 1)
            let fieldError = error.errors.first
            if case .requiredFieldEmptyValue? = fieldError {
                XCTAssertEqual(fieldError?.fieldName, edtiableForm.name)
            } else {
                XCTFail("The Field error should be requiredFieldEmptyValue")
            }
        } catch {
            XCTFail("Should only have Form ValidationError")
        }

        form.fields[1].text = "1234"
        do {
            try form.validateFields()
        } catch {
            XCTFail("Should not have ValidationError")
        }
    }
}
