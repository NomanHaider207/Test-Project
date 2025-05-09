import UIKit

class AddAppointmentViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var clientNameTextView: UITextField!
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

    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = AppEnvironment.shared.viewModel
        
        Task {
            await viewModel.loadEmployees()
            setupPickers()
            setupDatePickers()
        }
    }
    
    // MARK: - Date Picker Setup
       private func setupDatePickers() {
           // Configure the startDatePicker
           let now = Date()
           
           startDatePicker.datePickerMode = .dateAndTime
           startDatePicker.preferredDatePickerStyle = .wheels
           startDatePicker.minuteInterval = 10
           startDatePicker.minimumDate = now
           startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
           startTimeTextView.inputView = startDatePicker

           // Configure the endDatePicker
           endDatePicker.datePickerMode = .dateAndTime
           endDatePicker.preferredDatePickerStyle = .wheels
           endDatePicker.minuteInterval = 10
           endDatePicker.minimumDate = now
           endDatePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
           endTimeTextView.inputView = endDatePicker
       }

       // MARK: - Date Picker Value Changed
       @objc private func startDateChanged() {
           let formatter = DateFormatter()
           formatter.dateStyle = .short
           formatter.timeStyle = .short
           startTimeTextView.text = formatter.string(from: startDatePicker.date)
       }

       @objc private func endDateChanged() {
           let formatter = DateFormatter()
           formatter.dateStyle = .short
           formatter.timeStyle = .short
           
           // Check if the selected end time is earlier than the start time
           if endDatePicker.date < startDatePicker.date {
               // If the end time is invalid (before the start time), show an alert and reset the end time
               showAlert(message: "End time cannot be earlier than the start time.")
               endTimeTextView.text = "" // Reset the end time
               return
           }
           
           endTimeTextView.text = formatter.string(from: endDatePicker.date)
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

        let start = startDatePicker.date
        let end = endDatePicker.date

        Task {
            do {
                let employeeEntity = try await viewModel.fetchEmployeeEntity(by: employee.id)
                let serviceEntities = try await viewModel.fetchServiceEntities(by: selectedServices.map { $0.id })

                await viewModel.createAppointment(clientName: clientName, startTime: start, endTime: end, employee: employeeEntity, services: serviceEntities)

                await MainActor.run {
                    let alert = UIAlertController(title: "Success", message: "Appointment added successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
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
