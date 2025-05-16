// DefaultViewModel.swift - Complete refactored version

import Foundation
import UIKit

protocol ViewModelDelegate: AnyObject {
    func didFailWithError(_ error: Error)
    func didUpdateData()
}

@MainActor
final class DefaultViewModel: ObservableObject {

    // MARK: - Dependencies
    private let networkManager: NetworkManager
    weak var delegate: ViewModelDelegate?

    // MARK: - Published Properties
    @Published var appointments: [AppointmentModel] = []
    @Published var employees: [EmployeeModel] = []
    @Published var selectedDate: Date = Date() {
        didSet { filterAppointments() }
    }
    @Published var selectedEmployeeId: UUID? = nil {
        didSet { filterAppointments() }
    }

    // MARK: - Private Properties
    var allAppointments: [AppointmentModel] = []

    // MARK: - Initializer
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    // MARK: - Load Methods
    func loadEmployees() async {
        let result = await networkManager.getEmployees()
        switch result {
        case .success(let employees):
            let allOption = EmployeeModel(id: UUID(), name: "All", services: [])
            self.employees = [allOption] + employees
            delegate?.didUpdateData()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }

    func loadAppointments() async {
        let result = await networkManager.getAppointments()
        switch result {
        case .success(let appointments):
            self.allAppointments = appointments
            filterAppointments()
            delegate?.didUpdateData()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }

    // MARK: - Delete
    func deleteAppointment(_ id: UUID) async {
        guard let appointmentEntity = await fetchAppointmentById(id) else { return }
        let result = await networkManager.removeAppointment(appointmentEntity)
        switch result {
        case .success:
            await loadAppointments()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }

    // MARK: - Fetch by ID
    func fetchAppointmentById(_ id: UUID) async -> Appointmemts? {
        let result = await networkManager.getAppointment(by: id)
        switch result {
        case .success(let appointment):
            return appointment
        case .failure(let error):
            delegate?.didFailWithError(error)
            return nil
        }
    }
    
    // MARK: - Appointment Formatting
    func formatServicesList(_ services: [ServiceModel]) -> String {
        return services.map { $0.title }.joined(separator: ", ")
    }
    
    // MARK: - Employee Selection
    func isAllEmployeesOption(at index: Int) -> Bool {
        guard index < employees.count else { return false }
        return employees[index].name == "All"
    }
    
    func selectEmployee(at index: Int) {
        guard index < employees.count else { return }
        let selectedEmployee = employees[index]
        selectedEmployeeId = selectedEmployee.name == "All" ? nil : selectedEmployee.id
    }
    
    // MARK: - Filter Appointments
    func filterAppointments() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        self.appointments = allAppointments.filter { appointment in
            let overlaps = appointment.startTime < endOfDay && appointment.endTime >= startOfDay
            let matchesEmployee = selectedEmployeeId == nil || appointment.employee.id == selectedEmployeeId
            return overlaps && matchesEmployee
        }
        delegate?.didUpdateData()
    }
    
    func formattedTime(for appointment: AppointmentModel) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: appointment.startTime)) - \(formatter.string(from: appointment.endTime))"
    }
}
