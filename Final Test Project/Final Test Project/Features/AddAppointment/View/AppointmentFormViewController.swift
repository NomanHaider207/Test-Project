import UIKit

// MARK: - Protocols
protocol AddAppointmentDelegate: AnyObject {
    func didAddAppointment()
}



// MARK: - ViewController
class AppointmentFormViewController: UIViewController {

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
    @IBOutlet weak var startDateTimeContainer: UIStackView!
    @IBOutlet weak var endDateTimeContainer: UIStackView!
    
    
    // MARK: - Properties
    private var viewModel: AppointmentFormViewModel!
    var formMode: AppointmentFormMode = .add
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
            AlertManager.shared.showAlert(title: "Notice",message: "Please fill all fields and select at least one service.")
            return
        }

    switch formMode {
        case .add:
            createAppointment()
        case .edit(let existingAppointment):
            updateAppointment(existingAppointment: existingAppointment)
        }
    }

    @IBAction func backButtonPressed(_ sender: UIButton) {
        viewModel.resetSelectedEmployee()
        dismiss(animated: true)
    }

    @IBAction func startDateTimeDoneButtonPressed(_ sender: UIButton) {
        startTimeTextView.text = viewModel.formattedStartTime
        startDateTimeContainer.isHidden = true
    }
    
    @IBAction func endDateTimeDoneButtonPressed(_ sender: UIButton) {
        endTimeTextView.text = viewModel.formattedEndTime
        endDateTimeContainer.isHidden = true
    }
    
    
    // MARK: - Setup
    private func setupViewModel() {
        viewModel = AppointmentFormViewModel(networkManager: AppEnvironment.shared.networkManger, mode: formMode)
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
        startDateTimeContainer.isHidden = true
        endDateTimeContainer.isHidden = true
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
        let now = Date().roundedUpToNext5Minutes()

        startDateTimePicker.minuteInterval = 5
        startDateTimePicker.date = now
        startDateTimePicker.minimumDate = now
        startDateTimePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        startDateTimePicker.translatesAutoresizingMaskIntoConstraints = false
        startDateTimePicker.heightAnchor.constraint(equalToConstant: 135).isActive = true
        viewModel.updateStartTime(now)
        
        let endDateTime = viewModel.startDate?.addingTimeInterval(5 * 60).roundedUpToNext5Minutes()
        endDateTimePicker.minuteInterval = 5
        endDateTimePicker.minimumDate = endDateTime ?? Date().roundedUpToNext5Minutes()
        endDateTimePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        endDateTimePicker.translatesAutoresizingMaskIntoConstraints = false
        endDateTimePicker.heightAnchor.constraint(equalToConstant: 135).isActive = true
    }
    
    private func configureBasedOnSelectionType() {
        screenTitleLabel.text = viewModel.screenTitle
        buttonLabel.setTitle(viewModel.buttonTitle, for: .normal)
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
            AlertManager.shared.showAlert(title: "Notice", message: "Please select an employee first.")
            return
        }
        performSegue(withIdentifier: "showServiceSelection", sender: self)
    }

    // MARK: - DatePicker Events
    @objc private func startDateChanged() {
        let start = startDateTimePicker.date.roundedUpToNext5Minutes()
        viewModel.updateStartTime(start)
        startTimeTextView.text = viewModel.formattedStartTime
        
        startTimeTextView.resignFirstResponder()

        let endDateTime = viewModel.startDate?.addingTimeInterval(5 * 60).roundedUpToNext5Minutes()
        endDateTimePicker.date = endDateTime ?? Date().roundedUpToNext5Minutes()
        viewModel.updateEndTime(endDateTime ?? Date().roundedUpToNext5Minutes())
        endTimeTextView.text = ""
    }

    @objc private func endDateChanged() {
        let end = endDateTimePicker.date.roundedUpToNext5Minutes()
        
        if !viewModel.canSetEndTime(end) {
            AlertManager.shared.showAlert(title: "Notice", message: "End time cannot be earlier than start time.")
            endTimeTextView.text = ""
            return
        }

        viewModel.updateEndTime(end)
        endTimeTextView.text = viewModel.formattedEndTime
        endTimeTextView.resignFirstResponder()
        validateTimeRange()
    }

    @objc private func showConflictAlert() {
        AlertManager.shared.showAlert(title: "Notice",message: "This employee already has an appointment during this time.")
    }

    // MARK: - Validation
    private func validateTimeRange() {
        if !viewModel.validateTimeRange() {
            endTimeTextView.text = ""
        }
    }

    // MARK: - Appointment Logic
    private func createAppointment() {
        Task {
                print("[Add Appointment View Controller] - Create Appointment Function Called.")
                let success = await viewModel.createAppointment()
                if success {
                    await MainActor.run {
                        AlertManager.shared.showAlert(title: "Success", message: "Appointment added successfully.") {
                            self.delegate?.didAddAppointment()
                            self.dismiss(animated: true)
                        }
                    }
            }
        }
    }
    
    private func updateAppointment(existingAppointment: Appointments) {
        Task {
            let success = await viewModel.updateAppointment(existingAppointment: existingAppointment)
            if success {
                await MainActor.run {
                    AlertManager.shared.showAlert(title: "Success", message: "Appointment updated successfully.") {
                        self.delegate?.didAddAppointment()
                        self.dismiss(animated: true)
                    }
                }
            } else {
                AlertManager.shared.showAlert(title: "Error", message: "Error while updating appointment")
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
extension AppointmentFormViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Hide all
        employeePickerView.isHidden = true
        startDateTimeContainer.isHidden = true
        endDateTimeContainer.isHidden = true
        selectEmployeeTextView.isHidden = false

        switch textField {
        case selectEmployeeTextView:
            selectEmployeeTextView.isHidden = true
            employeePickerView.isHidden = false
        case startTimeTextView:
            startDateTimeContainer.isHidden = false
        case endTimeTextView:
            endDateTimeContainer.isHidden = false
        default:
            break
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case clientNameTextView:
            let currentText = (textField.text ?? "") as NSString
            let updatedText = currentText.replacingCharacters(in: range, with: string)
            
            viewModel.clientName = updatedText

            if updatedText.isEmpty {
                clientNameErrorLabel.isHidden = true
            } else if viewModel.validateName(updatedText) {
                clientNameErrorLabel.isHidden = true
            } else {
                clientNameErrorLabel.isHidden = false
                clientNameErrorLabel.text = "Name must contain alphabets only"
            }
            return true
            
        case startTimeTextView, endTimeTextView:
            return false
            
        default:
            return true
        }
    }

    
    private func handleClientNameValidation(_ textField: UITextField, range: NSRange, replacementString string: String) {
        let currentText = (textField.text ?? "") as NSString
        let updatedText = currentText.replacingCharacters(in: range, with: string)

        if updatedText.isEmpty {
            clientNameErrorLabel.isHidden = true
            return
        }

        if viewModel.validateName(updatedText) {
            clientNameErrorLabel.isHidden = true
        } else {
            clientNameErrorLabel.isHidden = false
            clientNameErrorLabel.text = "Name must contain alphabets only"
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == clientNameTextView {
            viewModel.clientName = textField.text ?? ""
        }
    }

}

// MARK: - UIPickerViewDelegate/DataSource
extension AppointmentFormViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
        selectServicesTextView.text = ""
        employeePickerView.isHidden = true
        selectEmployeeTextView.isHidden = false
        selectEmployeeTextView.resignFirstResponder()
    }
}

extension AppointmentFormViewController: ApointmentFormViewModlDelegate {
    
    func didFailWithError(_ error: any Error) {
        DispatchQueue.main.async {
            AlertManager.shared.showAlert(title:"Error",message: "\(error.localizedDescription)")
        }
    }
}
// MARK: - ServiceSelectionDelegate
extension AppointmentFormViewController: ServiceSelectionDelegate {
    func didSelectServices(_ services: [Services]) {
        viewModel.updateSelectedServices(services)
        selectServicesTextView.text = viewModel.selectedServicesText
    }
}


extension Date {
    func roundedUpToNext5Minutes() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let remainder = minute % 5
        let minutesToAdd = remainder == 0 ? 0 : (5 - remainder)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: self)!
    }
}
