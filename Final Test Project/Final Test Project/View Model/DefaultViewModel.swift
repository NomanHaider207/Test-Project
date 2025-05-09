import Foundation

@MainActor
final class DefaultViewModel: ObservableObject {
    
    private let repository: AppointmentRepositoryProtocol
    private let employeesRepository: EmployeeRepositoryProtocol
    private let servicesRepository: ServiceRepositoryProtocol

    @Published private(set) var appointments: [AppointmentModel] = []
    @Published private(set) var allAppointments: [AppointmentModel] = []
    @Published private(set) var employees: [EmployeeModel] = []

    @Published var selectedDate: Date = Date() {
        didSet {
            filterAppointments()
        }
    }

    @Published var selectedEmployeeId: UUID? = nil {
        didSet {
            filterAppointments()
        }
    }

    init(repository: AppointmentRepositoryProtocol, employeesRepository: EmployeeRepositoryProtocol, servicesRepository: ServiceRepositoryProtocol) {
        self.repository = repository
        self.employeesRepository = employeesRepository
        self.servicesRepository = servicesRepository
    }

    func loadEmployees() async {
        do {
            let employees = try await employeesRepository.fetchEmployeeModels()
            let allOption = EmployeeModel(id: UUID(), name: "All", services: [])
            self.employees = [allOption] + employees
        } catch {
            print("❌ Failed to load employees:", error)
        }
    }

    func loadAppointments() async {
        do {
            let appointments = try await repository.fetchAppointmentModels()
            self.allAppointments = appointments
            filterAppointments()
        } catch {
            print("❌ Failed to load appointments:", error)
        }
    }

    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        do {
            _ = try await repository.createAppointment(clientName: clientName, startTime: startTime, endTime: endTime, employee: employee, services: services)
            await loadAppointments()
        } catch {
            print("❌ Failed to create appointment:", error)
        }
    }

    func deleteAppointment(_ appointment: Appointmemts) async {
        do {
            try await repository.deleteAppointment(appointment)
            await loadAppointments()
        } catch {
            print("❌ Failed to delete appointment:", error)
        }
    }
    
    
    func getServicesForSelectedEmployee() async -> [ServiceModel] {
        guard let selectedId = selectedEmployeeId else {
            return []
        }
        
        do {
            let services = try await employeesRepository.fetchServices(for: selectedId)
            return services
        } catch {
            print("❌ Failed to fetch services for employee \(selectedId):", error)
            return []
        }
    }
    
    
    func fetchEmployeeEntity(by id: UUID) async throws -> Employees {
        return try await employeesRepository.fetchEmployeeEntity(by: id)
    }

    func fetchServiceEntities(by ids: [UUID]) async throws -> [Services] {
        return try await servicesRepository.fetchServiceEntities(by: ids)
    }


    private func filterAppointments() {
        let calendar = Calendar.current
        self.appointments = allAppointments.filter { appointment in
            let matchesDate = calendar.isDate(appointment.startTime, inSameDayAs: selectedDate)
            let matchesEmployee = selectedEmployeeId == nil || appointment.employee.id == selectedEmployeeId
            return matchesDate && matchesEmployee
        }
    }
}
