import Foundation

@MainActor
final class DefaultViewModel: ObservableObject {
    
    private let appointmentRepository: AppointmentRepositoryProtocol
    private let employeesRepository: EmployeeRepositoryProtocol
    private let servicesRepository: ServiceRepositoryProtocol

    @Published private(set) var appointments: [AppointmentModel] = []
    private(set) var allAppointments: [AppointmentModel] = []
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
        self.appointmentRepository = repository
        self.employeesRepository = employeesRepository
        self.servicesRepository = servicesRepository
    }

    func loadEmployees() async {
        do {
            let employees = try await employeesRepository.fetchEmployeeModels()
            let allOption = EmployeeModel(id: UUID(), name: "All", services: [])
            self.employees = [allOption] + employees
        } catch {
            print("Failed to load employees:", error)
        }
    }

    func loadAppointments() async {
        do {
            let appointments = try await appointmentRepository.fetchAppointmentModels()
            self.allAppointments = appointments
            filterAppointments()
        } catch {
            print("Failed to load appointments:", error)
        }
    }

    func createAppointment(clientName: String,appointmentDate: Date ,startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        do {
            let hasConflict = try await appointmentRepository.hasConflict(for: employee, on: appointmentDate, startTime: startTime, endTime: endTime)
                    
                    if hasConflict {
                        await MainActor.run {
                            NotificationCenter.default.post(name: NSNotification.Name("AppointmentConflict"), object: nil)
                        }
                        return
                    }
            _ = try await appointmentRepository.createAppointment(clientName: clientName,appointmentDate: appointmentDate ,startTime: startTime, endTime: endTime, employee: employee, services: services)
            await loadAppointments()
        } catch {
            print("Failed to create appointment:", error)
        }
    }

    func deleteAppointment(_ appointment: Appointmemts) async {
        do {
            try await appointmentRepository.deleteAppointment(appointment)
            await loadAppointments()
        } catch {
            print("Failed to delete appointment:", error)
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
            print("Failed to fetch services for employee \(selectedId):", error)
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
    
    func fetchAppointmentById(by id: UUID) async -> Appointmemts? {
        do {
            let appointment = try await appointmentRepository.fetchAppointmentEntity(by: id)
            return appointment
        } catch {
            print("Failed to fetch appointment with ID \(id):", error)
            return nil
        }
    }
}
