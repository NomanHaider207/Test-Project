import UIKit

// MARK: - Protocols
protocol AddAppointmentDelegate: AnyObject {
    func didAddAppointment()
}


// MARK: - Enums
enum ScreenMode {
    case addAppointment
    case editAppointment(existingAppointment: AppointmentModel)
}

// MARK: - ViewController
class AddAppointmentViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var clientNameTextView: UITextField!
    @IBOutlet weak var clientNameErrorLabel: UILabel!
    @IBOutlet weak var startTimeTextView: UITextField!
    @IBOutlet weak var endTimeTextView: UITextField!
    @IBOutlet weak var selectEmployeeTextView: UITextField!
    @IBOutlet weak var selectServicesTextView: UITextField!
    @IBOutlet weak var employeePickerView: UIPickerView!
    @IBOutlet weak var startDateTimePicker: UIDatePicker!
    @IBOutlet weak var endDateTimePicker: UIDatePicker!
    @IBOutlet weak var buttonLabel: UIButton!
    
    // MARK: - Properties
    private var viewModel: AddAppointmentViewModel!
    var selectionType: ScreenMode = .addAppointment
    weak var delegate: AddAppointmentDelegate?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        configureBasedOnSelectionType()
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.resetSelectedEmployee()
    }
    
    // MARK: - Actions
    @IBAction func onCreateAppointmentButtonPressed(_ sender: UIButton) {
        guard viewModel.validateAllFields(clientName: clientNameTextView.text) else {
            Utilities.shared.showAlert(title: "Notice",message: "Please fill all fields and select at least one service.")
            return
        }

        switch selectionType {
        case .addAppointment:
            createAppointment()
        case .editAppointment(let existingAppointment):
            updateAppointment(existingAppointment: existingAppointment)
        }
    }

    @IBAction func backButtonPressed(_ sender: UIButton) {
        viewModel.resetSelectedEmployee()
        dismiss(animated: true)
    }

    // MARK: - Setup
    private func setupViewModel() {
        viewModel = AddAppointmentViewModel(networkManager: AppEnvironment.shared.networkManger)
        viewModel.delegate = self
    }
    
    private func setupUI() {
        setupInitialVisibility()
        setupDelegates()
        setupTaps()
        setupPickers()
        setupDatePickers()
        setupNotifications()
    }
    
    private func setupInitialVisibility() {
        employeePickerView.isHidden = true
        startDateTimePicker.isHidden = true
        endDateTimePicker.isHidden = true
        clientNameErrorLabel.isHidden = true
    }

    private func setupDelegates() {
        clientNameTextView.delegate = self
        selectEmployeeTextView.delegate = self
        selectServicesTextView.delegate = self
        startTimeTextView.delegate = self
        endTimeTextView.delegate = self
    }

    private func setupTaps() {
        selectServicesTextView.inputView = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(serviceFieldTapped))
        selectServicesTextView.addGestureRecognizer(tap)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(showConflictAlert), name: NSNotification.Name("AppointmentConflict"), object: nil)
    }

    private func setupPickers() {
        employeePickerView.delegate = self
        employeePickerView.dataSource = self
        employeePickerView.translatesAutoresizingMaskIntoConstraints = false
        employeePickerView.heightAnchor.constraint(equalToConstant: 125).isActive = true
    }

    private func setupDatePickers() {
        let now = Date()

        startDateTimePicker.minuteInterval = 5
        startDateTimePicker.date = now
        startDateTimePicker.minimumDate = now
        startDateTimePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        startDateTimePicker.translatesAutoresizingMaskIntoConstraints = false
        startDateTimePicker.heightAnchor.constraint(equalToConstant: 135).isActive = true
        
        endDateTimePicker.minuteInterval = 5
        endDateTimePicker.minimumDate = now
        endDateTimePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        endDateTimePicker.translatesAutoresizingMaskIntoConstraints = false
        endDateTimePicker.heightAnchor.constraint(equalToConstant: 135).isActive = true
    }
    
    private func configureBasedOnSelectionType() {
        switch selectionType {
        case .addAppointment:
            break
        case .editAppointment(let appointment):
            screenTitleLabel.text = "Update Appoinment"
            buttonLabel.setTitle("Save", for: .normal)
            viewModel.populateDataForEditing(with: appointment)
            updateUIForEditing()
        }
    }
    
    private func updateUIForEditing() {
        clientNameTextView.text = viewModel.clientName
        startTimeTextView.text = viewModel.formattedStartTime
        endTimeTextView.text = viewModel.formattedEndTime
        selectEmployeeTextView.text = viewModel.selectedEmployeeName
        selectServicesTextView.text = viewModel.selectedServicesText
        
        startDateTimePicker.date = viewModel.startDate ?? Date()
        endDateTimePicker.date = viewModel.endDate ?? Date()
    }
    
    private func loadData() {
        Task {
            await viewModel.loadEmployees()
            employeePickerView.reloadAllComponents()
        }
    }
    
    @objc private func serviceFieldTapped() {
        if !viewModel.canSelectServices() {
            Utilities.shared.showAlert(title: "Notice", message: "Please select an employee first.")
            return
        }
        performSegue(withIdentifier: "showServiceSelection", sender: self)
    }

    // MARK: - DatePicker Events
    @objc private func startDateChanged() {
        let start = startDateTimePicker.date
        viewModel.updateStartTime(start)
        startTimeTextView.text = viewModel.formattedStartTime
        
        startTimeTextView.resignFirstResponder()
        startDateTimePicker.isHidden = true
        
        endTimeTextView.text = ""
    }

    @objc private func endDateChanged() {
        let end = endDateTimePicker.date
        
        if !viewModel.canSetEndTime(end) {
            Utilities.shared.showAlert(title: "Notice", message: "End time cannot be earlier than start time.")
            endTimeTextView.text = ""
            return
        }

        viewModel.updateEndTime(end)
        endTimeTextView.text = viewModel.formattedEndTime
        
        endTimeTextView.resignFirstResponder()
        endDateTimePicker.isHidden = true
        
        validateTimeRange()
    }

    @objc private func showConflictAlert() {
        Utilities.shared.showAlert(title: "Notice",message: "This employee already has an appointment during this time.")
    }

    // MARK: - Validation
    private func validateTimeRange() {
        if !viewModel.validateTimeRange() {
            endTimeTextView.text = ""
            Utilities.shared.showAlert(title: "Notice",message: "Invalid time range. Appointment can't be longer than 5 hours.")
        }
    }

    // MARK: - Appointment Logic
    private func createAppointment() {
        Task {
                let success = await viewModel.createAppointment(clientName: clientNameTextView.text ?? "")
                if success {
                    await MainActor.run {
                        Utilities.shared.showAlert(title: "Success", message: "Appointment updated successfully.") {
                            self.delegate?.didAddAppointment()
                            self.dismiss(animated: true)
                        }
                    }
            }
        }
    }
    
    private func updateAppointment(existingAppointment: AppointmentModel) {
        Task {
            do {
                let success = await viewModel.updateAppointment(existingAppointment: existingAppointment, clientName: clientNameTextView.text ?? "")
                if success {
                    await MainActor.run {
                        Utilities.shared.showAlert(title: "Success", message: "Appointment updated successfully.") {
                            self.delegate?.didAddAppointment()
                            self.dismiss(animated: true)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    Utilities.shared.showAlert(title: "Error", message: "Failed to update appointment: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showServiceSelection",
           let destinationVC = segue.destination as? ServiceSelectionViewController {
            destinationVC.availableServices = viewModel.availableServicesForEmployee
            destinationVC.selectedServices = viewModel.selectedServices
            destinationVC.delegate = self
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddAppointmentViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Hide all
        employeePickerView.isHidden = true
        startDateTimePicker.isHidden = true
        endDateTimePicker.isHidden = true
        selectEmployeeTextView.isHidden = false

        switch textField {
        case selectEmployeeTextView:
            selectEmployeeTextView.isHidden = true
            employeePickerView.isHidden = false
        case startTimeTextView:
            startDateTimePicker.isHidden = false
        case endTimeTextView:
            endDateTimePicker.isHidden = false
        default:
            break
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == clientNameTextView {
            let currentText = (textField.text ?? "") as NSString
            let updatedText = currentText.replacingCharacters(in: range, with: string)
            
            clientNameErrorLabel.isHidden = viewModel   .validateName(updatedText)
            if !clientNameErrorLabel.isHidden {
                clientNameErrorLabel.text = "Name must contain alphabets only"
            }
        }
        return true
    }
}

// MARK: - UIPickerViewDelegate/DataSource
extension AddAppointmentViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.employees.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.employees[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 30 }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.selectEmployee(at: row)
        selectEmployeeTextView.text = viewModel.selectedEmployeeName
        
        Task {
            await viewModel.loadServicesForSelectedEmployee()
            selectServicesTextView.text = ""
        }

        employeePickerView.isHidden = true
        selectEmployeeTextView.isHidden = false
        selectEmployeeTextView.resignFirstResponder()
    }
}

extension AddAppointmentViewController: AddApointmentViewModlDelegate {
    
    func didFailWithError(_ error: any Error) {
        DispatchQueue.main.async {
            Utilities.shared.showAlert(title:"Error",message: "Failed to update appointment: \(error.localizedDescription)")
        }
    }
}
// MARK: - ServiceSelectionDelegate
extension AddAppointmentViewController: ServiceSelectionDelegate {
    func didSelectServices(_ services: [ServiceModel]) {
        viewModel.updateSelectedServices(services)
        selectServicesTextView.text = viewModel.selectedServicesText
    }
}
