import UIKit
import TinkLink

final class FormTableViewController: UITableViewController {
    var onSubmit: (() -> Void)?
    var errorText: String?
    var prefillStrategy: TinkLinkViewController.PrefillStrategy = .none

    private(set) var form: Form

    private var currentScrollPos: CGFloat?
    private var errors: [IndexPath: Form.Field.ValidationError] = [:]

    init(form: Form) {
        self.form = form
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .clear
        tableView.registerReusableCell(ofType: FormFieldTableViewCell.self)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
    }

    func validateFields() -> Bool {
        view.endEditing(false)

        var indexPathsToUpdate = Set(errors.keys)
        errors = [:]

        do {
            try form.validateFields()
            tableView.reloadRows(at: Array(indexPathsToUpdate), with: .automatic)
            return true

        } catch let error as Form.ValidationError {
            for (index, field) in form.fields.enumerated() {
                guard let error = error[fieldName: field.name] else {
                    continue
                }
                let indexPath = IndexPath(row: index, section: 0)
                errors[indexPath] = error
                indexPathsToUpdate.insert(indexPath)
                tableView.reloadRows(at: Array(indexPathsToUpdate), with: .automatic)
                return false
            }
        } catch {
            assertionFailure("validateFields should only throw Form.ValidationError")
        }
        return false
    }
}

// MARK: - UITableViewDataSource

extension FormTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form.fields.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let field = form.fields[indexPath.item]

        let cell = tableView.dequeueReusableCell(ofType: FormFieldTableViewCell.self, for: indexPath)
        var viewModel = FormFieldTableViewCell.ViewModel(field: field)
        for value in prefillStrategy.values {
            switch value {
            case .username(let name, let isEditable):
                if indexPath.row == 0 {
                    var testField = field
                    testField.text = name
                    guard testField.isValid else { break }
                    viewModel.text = name
                    viewModel.isEditable = isEditable ? field.attributes.isEditable : false
                }
            }
        }
        cell.configure(with: viewModel)
        cell.delegate = self
        cell.setError(with: errors[indexPath]?.localizedDescription)
        cell.textField.returnKeyType = indexPath.row < (form.fields.count - 1) ? .next : .continue
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let errorText = errorText {
            return FormTableViewErrorView(errorText: errorText)
        } else {
            return nil
        }
    }
}

// MARK: - TextFieldCellDelegate

extension FormTableViewController: FormFieldTableViewCellDelegate {
    func formFieldCellShouldReturn(_ cell: FormFieldTableViewCell) -> Bool {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return true
        }

        let lastIndexItem = form.fields.count - 1
        if lastIndexItem == indexPath.item {
            onSubmit?()
            return true
        }

        let nextIndexPath = IndexPath(row: indexPath.item + 1, section: indexPath.section)

        guard form.fields.count > nextIndexPath.item,
              form.fields[indexPath.item + 1].attributes.isEditable,
              let nextCell = tableView.cellForRow(at: nextIndexPath)
        else {
            cell.resignFirstResponder()
            return true
        }

        nextCell.becomeFirstResponder()

        return false
    }

    func formFieldCell(_ cell: FormFieldTableViewCell, willChangeToText text: String) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        form.fields[indexPath.item].text = text
        errors[indexPath] = nil
        currentScrollPos = tableView.contentOffset.y
        tableView.beginUpdates()
        cell.setError(with: nil)
        tableView.endUpdates()
        currentScrollPos = nil
    }

    func formFieldCellDidEndEditing(_ cell: FormFieldTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        let field = form.fields[indexPath.item]

        do {
            try field.validate()
            errors[indexPath] = nil
        } catch let error as Form.Field.ValidationError {
            errors[indexPath] = error
        } catch {
            print("Unknown error \(error).")
        }
        currentScrollPos = tableView.contentOffset.y
        tableView.reloadRows(at: [indexPath], with: .automatic)
        currentScrollPos = nil
    }

    // To fix the issue for scroll view jumping while animating the cell, inspired by
    // https://stackoverflow.com/questions/33789807/uitableview-jumps-up-after-begin-endupdates-when-using-uitableviewautomaticdimen
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Force the tableView to stay at scroll position until animation completes
        if let currentScrollPos = currentScrollPos {
            tableView.setContentOffset(CGPoint(x: 0, y: currentScrollPos), animated: false)
        }
    }
}
