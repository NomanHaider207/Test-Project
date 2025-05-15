//
//  AddAppointmentViewModel.swift
//  Final Test Project
//
//  Created by Dev on 5/14/25.
//

import Foundation

protocol AddApointmentViewModlDelegate: AnyObject {
    func didFailWithError(_ error: Error)
}
// MARK: - AddAppointmentViewModel
@MainActor
class AddAppointmentViewModel {
    
    // MARK: - Properties
    weak var delegate: AddApointmentViewModlDelegate?
    private var networkManager: NetworkManager?
    
    var selectedEmployee: EmployeeModel?
    var selectedServices: [ServiceModel] = []
    var availableServicesForEmployee: [ServiceModel] = []
    var startDate: Date?
    var endDate: Date?
    var clientName: String = ""
    var employees: [EmployeeModel] = []
    var selectedEmployeeId: UUID? = nil
    
    // MARK: - Init
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    // MARK: - Computed Properties
    var selectedEmployeeName: String {
        return selectedEmployee?.name ?? ""
    }
    
    var formattedStartTime: String {
        guard let date = startDate else { return "" }
        return formatDate(date)
    }
    
    var formattedEndTime: String {
        guard let date = endDate else { return "" }
        return formatDate(date)
    }
    
    var selectedServicesText: String {
        return selectedServices.map { $0.title }.joined(separator: ", ")
    }
    
    // MARK: - Public Methods
    func loadEmployees() async {
        let result = await networkManager?.getEmployees()
        switch result {
        case .success(let fetchedEmployees):
            employees = fetchedEmployees
        case .failure(let error):
            delegate?.didFailWithError(error)
        case .none:
            break
        }
    }
    
    func selectEmployee(at index: Int) {
        selectedEmployee = employees[index]
        selectedEmployeeId = selectedEmployee?.id
        selectedServices = []
    }
    
    func resetSelectedEmployee() {
        selectedEmployee = nil
        selectedEmployeeId = nil
    }
    
    func updateStartTime(_ date: Date) {
        startDate = date
        endDate = nil
    }
    
    func updateEndTime(_ date: Date) {
        endDate = date
    }
    
    func canSetEndTime(_ endTime: Date) -> Bool {
        guard let start = startDate else { return false }
        return endTime > start
    }
    
    func validateTimeRange() -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        return validateAppointmentInput(startTime: start, endTime: end)
    }
    
    func validateName(_ name: String) -> Bool {
        return isUserNameValid(name)
    }
    
    func canSelectServices() -> Bool {
        return selectedEmployee != nil
    }
    
    func updateSelectedServices(_ services: [ServiceModel]) {
        selectedServices = services
    }
    
    func loadServicesForSelectedEmployee() async {
        availableServicesForEmployee = await getServicesForSelectedEmployee()
        selectedServices = []
    }
    
    func populateDataForEditing(with appointment: AppointmentModel) {
        clientName = appointment.clientName
        startDate = appointment.startTime
        endDate = appointment.endTime
        selectedEmployee = appointment.employee
        selectedServices = appointment.services
        selectedEmployeeId = appointment.employee.id
    }
    
    func getServicesForSelectedEmployee() async -> [ServiceModel] {
        guard let selectedId = selectedEmployeeId else { return [] }
        
        let result = await networkManager?.getEmployeeServices(for: selectedId)
        switch result {
        case .success(let serviceModels):
            return serviceModels
        case .failure(let error):
            delegate?.didFailWithError(error)
            return []
        case .none:
            return []
        }
    }
    
    func validateAllFields(clientName: String?) -> Bool {
        guard let name = clientName, !name.isEmpty else { return false }
        if !validateName(name) { return false }
        guard selectedEmployee != nil else { return false }
        if selectedServices.isEmpty { return false }
        guard let start = startDate, let end = endDate else { return false }
        if end <= start { return false }
        return validateTimeRange()
    }
    
    func createAppointment(clientName: String) async -> Bool {
        guard validateAllFields(clientName: clientName),
              let employee = selectedEmployee,
              let startTime = startDate,
              let endTime = endDate else {
            return false
        }
        
        let employeeResult = await networkManager?.getEmployee(by: employee.id)
        guard case .success(let employeeEntity) = employeeResult else {
            delegate?.didFailWithError(NSError(domain: "AppointmentError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Employee not found"]))
            return false
        }

        let serviceResult = await networkManager?.getServices(by: selectedServices.map { $0.id })
        guard case .success(let serviceEntities) = serviceResult else {
            delegate?.didFailWithError(NSError(domain: "AppointmentError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Service loading failed"]))
            return false
        }

        let result = await networkManager?.addAppointment(
            clientName: clientName,
            startTime: startTime,
            endTime: endTime,
            employee: employeeEntity,
            services: serviceEntities
        )

        switch result {
        case .success(let created):
            return created
        case .failure(let error):
            delegate?.didFailWithError(error)
            return false
        case .none:
            return false
        }
    }
    
    func updateAppointment(existingAppointment: AppointmentModel, clientName: String) async -> Bool {
        guard validateAllFields(clientName: clientName),
              let employee = selectedEmployee,
              let startTime = startDate,
              let endTime = endDate else {
            return false
        }
        
        let employeeResult = await networkManager?.getEmployee(by: employee.id)
        guard case .success(let employeeEntity) = employeeResult else {
            delegate?.didFailWithError(NSError(domain: "AppointmentError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Employee not found"]))
            return false
        }

        let serviceResult = await networkManager?.getServices(by: selectedServices.map { $0.id })
        guard case .success(let serviceEntities) = serviceResult else {
            delegate?.didFailWithError(NSError(domain: "AppointmentError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Service loading failed"]))
            return false
        }

        let result = await networkManager?.updateAppointment(
            appointment: existingAppointment,
            clientName: clientName,
            startTime: startTime,
            endTime: endTime,
            employee: employeeEntity,
            services: serviceEntities
        )

        switch result {
        case .success:
            return true
        case .failure(let error):
            delegate?.didFailWithError(error)
            return false
        case .none:
            return false
        }
    }
    
    // MARK: - Private Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isUserNameValid(_ name: String) -> Bool {
        return Validator.isValidUserName(name)
    }
    
    private func validateAppointmentInput(startTime: Date, endTime: Date) -> Bool {
        switch Validator.validateAppointmentDuration(startTime: startTime, endTime: endTime) {
        case .success:
            return true
        case .failure(let error):
            delegate?.didFailWithError(error)
            return false
        }
    }
}
