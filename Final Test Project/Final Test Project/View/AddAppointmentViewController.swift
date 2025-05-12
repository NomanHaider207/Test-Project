import UIKit

// MARK: - AddAppointmentDelegate
protocol AddAppointmentDelegate: AnyObject {
    func didAddAppointment()
}

class AddAppointmentViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var clientNameTextView: UITextField!
    @IBOutlet weak var appointmentDateTextView: UITextField!
    @IBOutlet weak var startTimeTextView: UITextField!
    @IBOutlet weak var endTimeTextView: UITextField!
    @IBOutlet weak var selectEmployeeTextView: UITextField!
    @IBOutlet weak var selectServicesTextView: UITextField!
    
    // MARK: - Properties
    private var viewModel: DefaultViewModel!
    private var employeePickerView = UIPickerView()
    private var selectedEmployee: EmployeeModel?
    private var selectedServices: [ServiceModel] = []
    private var availableServicesForEmployee: [ServiceModel] = []

    private var filteredEmployees: [EmployeeModel] {
           return Array(viewModel.employees.dropFirst())
    }
    
    weak var delegate: AddAppointmentDelegate?
    
    private let datePicker = UIDatePicker()
    private let startTimePicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = AppEnvironment.shared.viewModel
        NotificationCenter.default.addObserver(self, selector: #selector(showConflictAlert), name: NSNotification.Name("AppointmentConflict"), object: nil)
        
        Task {
            await viewModel.loadEmployees()
            setupPickers()
            setupDatePickers()
        }
    }
    
    // MARK: - Date Picker Setup
    private func setupDatePickers() {
        let now = Date()
        
        // Date Picker to select date only
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = now
        datePicker.minimumDate = now
        datePicker.addTarget(self, action: #selector(appointmentDateChanged), for: .valueChanged)
        appointmentDateTextView.inputView = datePicker
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        appointmentDateTextView.text = dateFormatter.string(from: now)
        
        // Configure the startTimePicker (for time only)
        startTimePicker.datePickerMode = .time
        startTimePicker.preferredDatePickerStyle = .wheels
        startTimePicker.minuteInterval = 5
        startTimePicker.date = now
        startTimePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        startTimeTextView.inputView = startTimePicker

        // Configure the endTimePicker (for time only)
        endTimePicker.datePickerMode = .time
        endTimePicker.preferredDatePickerStyle = .wheels
        endTimePicker.minuteInterval = 5
        endTimePicker.date = Calendar.current.date(byAdding: .minute, value: 5, to: now)!
        endTimePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        endTimeTextView.inputView = endTimePicker
    }

    // MARK: - Date Picker Value Changed
    @objc private func appointmentDateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        appointmentDateTextView.text = formatter.string(from: datePicker.date)
    }

    @objc private func startDateChanged() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let selectedStartTime = startTimePicker.date
        startTimeTextView.text = formatter.string(from: selectedStartTime)
        
        let minEndTime = Calendar.current.date(byAdding: .minute, value: 5, to: selectedStartTime)!
        endTimePicker.minimumDate = minEndTime
        endTimePicker.date = minEndTime
        endTimeTextView.text = formatter.string(from: minEndTime)
    }

    @objc private func endDateChanged() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if endTimePicker.date < startTimePicker.date {
            showAlert(message: "End time cannot be earlier than the start time.")
            endTimeTextView.text = ""
            return
        }
        endTimeTextView.text = formatter.string(from: endTimePicker.date)
    }


    // MARK: - Picker Setup
    private func setupPickers() {
        // Employee Picker
        employeePickerView.delegate = self
        employeePickerView.dataSource = self
        selectEmployeeTextView.inputView = employeePickerView

        // Services Picker trigger
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showServiceSelection))
        selectServicesTextView.addGestureRecognizer(tapGesture)
        selectServicesTextView.isUserInteractionEnabled = true
    }

    // MARK: - Service Selection
    @objc private func showServiceSelection() {
        guard selectedEmployee != nil else {
            showAlert(message: "Please select an employee first.")
            return
        }

        let alert = UIAlertController(title: "Select Services", message: nil, preferredStyle: .alert)
        for service in availableServicesForEmployee {
            let isSelected = selectedServices.contains(where: { $0.id == service.id })

            alert.addAction(UIAlertAction(
                title: "\(isSelected ? "✓ " : "")\(service.title)",
                style: .default,   
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    
                    if let index = self.selectedServices.firstIndex(where: { $0.id == service.id }) {
                        self.selectedServices.remove(at: index)
                    } else {
                        self.selectedServices.append(service)
                    }

                    self.selectServicesTextView.text = self.selectedServices.map { $0.title }.joined(separator: ", ")
                }))
        }

        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.selectedEmployeeId = nil
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        viewModel.selectedEmployeeId = nil
        self.dismiss(animated: true)
    }
    
    
    // MARK: - Action on Creating appointment
    @IBAction func onCreateAppointmentButtonPressed(_ sender: UIButton) {
        guard
            let clientName = clientNameTextView.text, !clientName.isEmpty,
            let employee = selectedEmployee,
            !selectedServices.isEmpty
        else {
            showAlert(message: "Please fill all fields and select at least one service.")
            return
        }
        
        let appointmentDate = datePicker.date
        let start = startTimePicker.date
        let end = endTimePicker.date

        Task {
            do {
                let employeeEntity = try await viewModel.fetchEmployeeEntity(by: employee.id)
                let serviceEntities = try await viewModel.fetchServiceEntities(by: selectedServices.map { $0.id })

                await viewModel.createAppointment(clientName: clientName,appointmentDate: appointmentDate ,startTime: start, endTime: end, employee: employeeEntity, services: serviceEntities)
                await MainActor.run {
                    let alert = UIAlertController(title: "Success", message: "Appointment added successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.delegate?.didAddAppointment()
                        self.dismiss(animated: true)
                    }))
                    present(alert, animated: true)
                }

            } catch {
                await MainActor.run {
                    self.showAlert(message: "Failed to create appointment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func showConflictAlert() {
        showAlert(message: "This employee already has an appointment during this time.")
    }
}

// MARK: - UIPickerView Delegate/DataSource
extension AddAppointmentViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filteredEmployees.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filteredEmployees[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selected = filteredEmployees[row]
        selectedEmployee = selected
        viewModel.selectedEmployeeId = selected.id
        selectEmployeeTextView.text = selected.name

        Task {
            let services = await viewModel.getServicesForSelectedEmployee()
            self.availableServicesForEmployee = services
            selectedServices = []
            selectServicesTextView.text = ""
        }
        selectEmployeeTextView.resignFirstResponder()
    }
}
