//
//  AddAppointmentViewModel.swift
//  Final Test Project
//
//  Created by Dev on 5/14/25.
//

import Foundation

protocol ApointmentFormViewModlDelegate: AnyObject {
    func didFailWithError(_ error: Error)
}
// MARK: - AddAppointmentViewModel
@MainActor
class AppointmentFormViewModel {
    
    // MARK: - Properties
    weak var delegate: ApointmentFormViewModlDelegate?
    private var networkManager: RepositoryManager?
    
    var selectedEmployee: Employees?
    var selectedServices: [Services] = []
    var availableServicesForEmployee: [Services] = []
    var startDate: Date?
    var endDate: Date?
    var clientName: String = ""
    var employees: [Employees] = []
    var selectedEmployeeId: UUID? = nil
    
    // MARK: - Init
    init(networkManager: RepositoryManager) {
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
        return selectedServices.map { $0.title! }.joined(separator: ", ")
    }
    
    // MARK: - Public Methods
    func loadEmployees() async {
        let result = await networkManager?.getEmployees()
        switch result {
        case .success(let fetchedEmployees):
            // Drop the first employee if needed
            employees = Array(fetchedEmployees.dropFirst())
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
        guard let start = startDate, let end = endDate else {
            return true
        }
        return validateAppointmentInput(startTime: start, endTime: end)
    }

    
    func validateName(_ name: String) -> Bool {
        return isUserNameValid(name)
    }
    
    func canSelectServices() -> Bool {
        return selectedEmployee != nil
    }
    
    func updateSelectedServices(_ services: [Services]) {
        selectedServices = services
    }
    
    func loadServicesForSelectedEmployee() async {
        availableServicesForEmployee = await getServicesForSelectedEmployee()
        selectedServices = []
    }
    
    func populateDataForEditing(with appointment: Appointments){
        clientName = appointment.clientName!
        startDate = appointment.startTime!
        endDate = appointment.endTime!
        selectedEmployee = appointment.employee!
        selectedEmployeeId = appointment.employee?.id
        
        if let serviceSet = selectedEmployee?.services as? Set<Services> {
                availableServicesForEmployee = Array(serviceSet)
            } else {
                availableServicesForEmployee = []
        }
        
        if let serviceSet = appointment.services as? Set<Services> {
            selectedServices = Array(serviceSet)
            print("Selected services loaded: \(selectedServices.map { $0.title ?? "" })")
        } else {
            print("Failed to cast services to Set<Services>")
            selectedServices = []
        }
    }

    
    func getServicesForSelectedEmployee() async -> [Services] {
        guard let selectedId = selectedEmployeeId else { return [] }
        let result = await networkManager?.getEmployeeServices(for: selectedId)
        switch result {
        case .success(let services):
            return services
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
    
    func createAppointment() async -> Bool {
        guard validateAllFields(clientName: clientName),
              let employee = selectedEmployee,
              let startTime = startDate,
              let endTime = endDate else {
            return false
        }
        
        let mainContext = CoreDataManager.shared.mainContext
        
        guard let employeeInMainContext = mainContext.object(with: employee.objectID) as? Employees else {
            delegate?.didFailWithError(NSError(domain: "AppointmentError", code: 402, userInfo: [NSLocalizedDescriptionKey: "Failed to get employee in main context"]))
            return false
        }
        
        let servicesInMainContext = selectedServices.compactMap { service in
            return mainContext.object(with: service.objectID) as? Services
        }
        
        let result = await networkManager?.createAppointment(clientName: clientName, startTime: startTime, endTime: endTime, employee: employeeInMainContext, services: servicesInMainContext)
        switch result {
        case .success(let created):
            print(created)
            return created
        case .failure(let error):
            delegate?.didFailWithError(error)
            return false
        case .none:
            return false
        }
    }

    
    func updateAppointment(existingAppointment: Appointments) async -> Bool {
        guard validateAllFields(clientName: clientName),
              let _ = selectedEmployee,
              let startTime = startDate,
              let endTime = endDate else {
            return false
        }
        
        let result = await networkManager?.updateAppointment(
            with: existingAppointment,
            newClientName: clientName,
            newStartTime: startTime,
            newEndTime: endTime,
            selectedEmployee: selectedEmployee!,
            selectedServices: selectedServices
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
