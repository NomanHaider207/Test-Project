import UIKit

// MARK: - AddAppointmentDelegate
protocol AddAppointmentDelegate: AnyObject {
    func didAddAppointment()
}

// MARK: - Enum
enum SelectionType {
    case addAppointment
    case editAppointment(existingAppointment: AppointmentModel)
}

// MARK: - ViewController
class AddAppointmentViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var clientNameTextView: UITextField!
    @IBOutlet weak var startTimeTextView: UITextField!
    @IBOutlet weak var endTimeTextView: UITextField!
    @IBOutlet weak var selectEmployeeTextView: UITextField!
    @IBOutlet weak var selectServicesTextView: UITextField!
    @IBOutlet weak var employeePickerView: UIPickerView!
    @IBOutlet weak var startDateTimePicker: UIDatePicker!
    @IBOutlet weak var endDateTimePicker: UIDatePicker!
    @IBOutlet weak var buttonLabel: UIButton!
    
    // MARK: - Properties
    private var viewModel: DefaultViewModel!
    private var selectedEmployee: EmployeeModel?
    private var selectedServices: [ServiceModel] = []
    private var availableServicesForEmployee: [ServiceModel] = []
    
    var selectionType: SelectionType = .addAppointment
    weak var delegate: AddAppointmentDelegate?

    private var filteredEmployees: [EmployeeModel] {
        return Array(viewModel.employees.dropFirst())
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = AppEnvironment.shared.viewModel

        setupInitialVisibility()
        setupDelegates()
        setupTaps()
        setupPickers()
        setupDatePickers()
        setupNotifications()
        
        switch selectionType {
            case .addAppointment:
                break
            case .editAppointment(let appointment):
                screenTitleLabel.text = "Update Appoinment"
                buttonLabel.setTitle("Save", for: .normal)
                populateFields(with: appointment)
            }
        
        Task {
            await viewModel.loadEmployees()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.selectedEmployeeId = nil
    }

    // MARK: - Setup
    private func setupInitialVisibility() {
        employeePickerView.isHidden = true
        startDateTimePicker.isHidden = true
        endDateTimePicker.isHidden = true
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

    // MARK: - Actions
    @IBAction func onCreateAppointmentButtonPressed(_ sender: UIButton) {
        guard let clientName = clientNameTextView.text, !clientName.isEmpty,
              let employee = selectedEmployee,
              !selectedServices.isEmpty else {
            showAlert(message: "Please fill all fields and select at least one service.")
            return
        }

        switch selectionType {
        case .addAppointment:
            createAppointment(clientName: clientName,
                              startTime: startDateTimePicker.date,
                              endTime: endDateTimePicker.date,
                              employee: employee)

        case .editAppointment(let existingAppointment):
            updateAppointment(existingAppointment: existingAppointment,
                              clientName: clientName,
                              startTime: startDateTimePicker.date,
                              endTime: endDateTimePicker.date,
                              employee: employee)
        }
    }


    @IBAction func backButtonPressed(_ sender: UIButton) {
        viewModel.selectedEmployeeId = nil
        dismiss(animated: true)
    }

    @objc private func serviceFieldTapped() {
        guard selectedEmployee != nil else {
            showAlert(message: "Please select an employee first.")
            return
        }
        performSegue(withIdentifier: "showServiceSelection", sender: self)
    }

    // MARK: - DatePicker Events
    @objc private func startDateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let start = startDateTimePicker.date
        startTimeTextView.text = formatter.string(from: start)

        startTimeTextView.resignFirstResponder()
        startDateTimePicker.isHidden = true
    }

    @objc private func endDateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if endDateTimePicker.date < startDateTimePicker.date {
            showAlert(message: "End time cannot be earlier than the start time.")
            endTimeTextView.text = ""
            return
        }

        endTimeTextView.text = formatter.string(from: endDateTimePicker.date)
        endTimeTextView.resignFirstResponder()
        endDateTimePicker.isHidden = true
    }

    @objc private func showConflictAlert() {
        showAlert(message: "This employee already has an appointment during this time.")
    }

    // MARK: - Appointment Logic
    private func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: EmployeeModel) {
        Task {
            do {
                guard let employeeEntity = await viewModel.fetchEmployeeEntity(by: employee.id) else {
                    showErrorAlert(message: "Employee not found")
                    return
                }

                let serviceEntities = try await viewModel.fetchServiceEntities(by: selectedServices.map { $0.id })
                await viewModel.createAppointment(clientName: clientName, startTime: startTime, endTime: endTime, employee: employeeEntity, services: serviceEntities)

                await MainActor.run {
                    let alert = UIAlertController(title: "Success", message: "Appointment added successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.delegate?.didAddAppointment()
                        self.dismiss(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    showErrorAlert(message: "Failed to create appointment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Update Appointment Logic
    private func updateAppointment(existingAppointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: EmployeeModel) {
        Task {
            do {
                guard let employeeEntity = await viewModel.fetchEmployeeEntity(by: employee.id) else {
                    showErrorAlert(message: "Employee not found")
                    return
                }

                let serviceEntities = try await viewModel.fetchServiceEntities(by: selectedServices.map { $0.id })

                await viewModel.updateAppointmentModel(appointment: existingAppointment,
                                                  clientName: clientName,
                                                  startTime: startTime,
                                                  endTime: endTime,
                                                  employee: employeeEntity,
                                                  services: serviceEntities)

                await MainActor.run {
                    let alert = UIAlertController(title: "Updated", message: "Appointment updated successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.delegate?.didAddAppointment()
                        self.dismiss(animated: true)
                    })
                    self.present(alert, animated: true)
                }

            } catch {
                await MainActor.run {
                    showErrorAlert(message: "Failed to update appointment: \(error.localizedDescription)")
                }
            }
        }
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showServiceSelection",
           let destinationVC = segue.destination as? ServiceSelectionViewController {
            destinationVC.availableServices = availableServicesForEmployee
            destinationVC.selectedServices = selectedServices
            destinationVC.delegate = self
        }
    }

    // MARK: - Alerts
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Populate Field In case on Editing
    private func populateFields(with appointment: AppointmentModel) {
        clientNameTextView.text = appointment.clientName
        startDateTimePicker.date = appointment.startTime
        endDateTimePicker.date = appointment.endTime

        startTimeTextView.text = format(date: appointment.startTime)
        endTimeTextView.text = format(date: appointment.endTime)

        selectedEmployee = appointment.employee
        selectEmployeeTextView.text = appointment.employee.name
        viewModel.selectedEmployeeId = appointment.employee.id

        selectedServices = appointment.services
        selectServicesTextView.text = appointment.services.map { $0.title }.joined(separator: ", ")
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}

// MARK: - UIPickerViewDelegate/DataSource
extension AddAppointmentViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { filteredEmployees.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { filteredEmployees[row].name }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 30 }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selected = filteredEmployees[row]
        selectedEmployee = selected
        viewModel.selectedEmployeeId = selected.id
        selectEmployeeTextView.text = selected.name

        Task {
            let services = await viewModel.getServicesForSelectedEmployee()
            availableServicesForEmployee = services
            selectedServices = []
            selectServicesTextView.text = ""
        }

        employeePickerView.isHidden = true
        selectEmployeeTextView.isHidden = false
        selectEmployeeTextView.resignFirstResponder()
    }
}

// MARK: - ViewModelDelegate
extension AddAppointmentViewController: ViewModelDelegate {
    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.showAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - ServiceSelectionDelegate
extension AddAppointmentViewController: ServiceSelectionDelegate {
    func didSelectServices(_ services: [ServiceModel]) {
        selectedServices = services
        selectServicesTextView.text = services.map { $0.title }.joined(separator: ", ")
    }
}
