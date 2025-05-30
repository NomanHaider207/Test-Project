// DefaultViewModel.swift - Complete refactored version

import Foundation
import UIKit

protocol ViewModelDelegate: AnyObject {
    func didFailWithError(_ error: Error)
    func didUpdateData()
}

@MainActor
final class AppointmentDashboardViewModel: ObservableObject {

    // MARK: - Dependencies
    private let networkManager: RepositoryManager
    weak var delegate: ViewModelDelegate?
    var screenMode: AppointmentFormMode = .add

    // MARK: - Published Properties
    @Published var appointments: [Appointments] = []
    @Published var employees: [Employees] = []
    @Published var selectedDate: Date = Date() {
        didSet { filterAppointments() }
    }
    @Published var selectedEmployeeId: UUID? = nil {
        didSet { filterAppointments() }
    }

    // MARK: - Private Properties
    var allAppointments: [Appointments] = []

    // MARK: - Initializer
    init(networkManager: RepositoryManager) {
        self.networkManager = networkManager
    }

    // MARK: - Load Methods
    func loadEmployees() async {
        let result = await networkManager.getEmployees()
        switch result {
        case .success(let employees):
            self.employees = employees
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }

    func loadAppointments() async {
        let result = await networkManager.getAllAppointments()
        switch result {
        case .success(let appointments):
            self.allAppointments = appointments
            filterAppointments()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }
    
    
    func creatDummyData() async {
        await networkManager.creatDummyData()
    }

    // MARK: - Delete
    func deleteAppointment(_ id: UUID) async {
        guard let appointmentEntity = await fetchAppointmentById(id) else { return }
        let result = await networkManager.deleteAppointment(appointmentEntity)
        switch result {
        case .success:
            await loadAppointments()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }
    
    // MARK: - Fetch by ID
    func fetchAppointmentById(_ id: UUID) async -> Appointments? {
        let result = await networkManager.getAppointmentById(by: id)
        switch result {
        case .success(let appointment):
            return appointment
        case .failure(let error):
            delegate?.didFailWithError(error)
            return nil
        }
    }
    
    // MARK: - Appointment Formatting
    func formatServicesList(_ services: [Services]) -> String {
        return services.compactMap { $0.title }.joined(separator: ", ")
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
            guard let startTime = appointment.startTime,
                  let endTime = appointment.endTime
            
            else {
                print("""
                    [Filter Check] - Appointment: \(appointment.clientName ?? "Unknown")
                    Start: \(String(describing: appointment.startTime)), End: \(String(describing: appointment.endTime))
                """)
                return false
            }

            let overlaps = startTime < endOfDay && endTime >= startOfDay
            let matchesEmployee = selectedEmployeeId == nil || appointment.employee?.id == selectedEmployeeId

            print("""
                [Filter Check] - Appointment: \(appointment.clientName ?? "Unknown")
                Start: \(startTime), End: \(endTime)
                Overlaps: \(overlaps), Matches Employee: \(matchesEmployee)
            """)

            return overlaps && matchesEmployee
        }
        print("[Appointment Dashboard] - [Appointments Arrays] - \(appointments)")
        delegate?.didUpdateData()
    }

    
    func formattedTime(for appointment: Appointments) -> String {
        guard let start = appointment.startTime,
              let end = appointment.endTime else {
            return "Invalid time"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    
    func getEmployeeListLength() -> Int {
        return employees.count
    }
    func getAppointmentListLength() -> Int{
        return appointments.count
    }
    
    func isEmployeeSelected(_ employee: Employees) -> Bool {
        if let selectedId = selectedEmployeeId {
            return employee.id == selectedId
        }
        return employee.name == "All"
    }
    
    func appointment(at section: Int) -> Appointments {
        return appointments[section]
    }

}
