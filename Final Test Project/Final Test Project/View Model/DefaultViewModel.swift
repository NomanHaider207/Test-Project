import Foundation

protocol ViewModelDelegate: AnyObject {
    func didFailWithError(_ error: Error)
}

@MainActor
final class DefaultViewModel: ObservableObject {
    
    private let appointmentRepository: AppointmentRepositoryProtocol
    private let employeesRepository: EmployeeRepositoryProtocol
    private let servicesRepository: ServiceRepositoryProtocol
    weak var delegate: ViewModelDelegate?

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
        let result = await employeesRepository.fetchEmployeeModels()
        switch result {
        case .success(let employees):
            let allOption = EmployeeModel(id: UUID(), name: "All", services: [])
            self.employees = [allOption] + employees
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }


    func loadAppointments() async {
            let results = await appointmentRepository.fetchAppointmentModels()
            switch results {
            case .success(let appointments):
                self.allAppointments = appointments
                filterAppointments()
            case .failure(let error):
                delegate?.didFailWithError(error)
            }
           
    }

    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        do {
            let hasConflict = try await appointmentRepository.hasConflict(for: employee, startTime: startTime, endTime: endTime)
                    
                    if hasConflict {
                        await MainActor.run {
                            NotificationCenter.default.post(name: NSNotification.Name("AppointmentConflict"), object: nil)
                        }
                        return
                    }
            _ = try await appointmentRepository.createAppointment(clientName: clientName,startTime: startTime, endTime: endTime, employee: employee, services: services)
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
        let result = await employeesRepository.fetchServices(for: selectedId)
        switch result {
        case .success(let serviceModels):
            return serviceModels
        case.failure(let error):
            delegate?.didFailWithError(error)
            return []
        }
    }
    
    func fetchEmployeeEntity(by id: UUID) async -> Employees? {
        
        let results = await employeesRepository.fetchEmployeeEntity(by: id)
        switch results {
        case .success(let employee):
            return employee
        case .failure(let error):
            delegate?.didFailWithError(error)
            return nil
        }
    }

    func fetchServiceEntities(by ids: [UUID]) async throws -> [Services] {
        return try await servicesRepository.fetchServiceEntities(by: ids)
    }


    private func filterAppointments() {
        let calendar = Calendar.current

        self.appointments = allAppointments.filter { appointment in
            let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
            guard let endOfSelectedDate = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDate) else {
                return false
            }

            let appointmentStart = appointment.startTime
            let appointmentEnd = appointment.endTime

            let isOverlapping = appointmentStart < endOfSelectedDate && appointmentEnd >= startOfSelectedDate

            let matchesEmployee = selectedEmployeeId == nil || appointment.employee.id == selectedEmployeeId

            return isOverlapping && matchesEmployee
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
    
    
    func fetchServices() async -> [ServiceModel] {
        let results = await servicesRepository.fetchServicesModel()
        switch results {
        case .success(let services):
            return services
        case .failure(let error):
            delegate?.didFailWithError(error)
            return []
        }
    }
    
    func updateAppointmentModel(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        await appointmentRepository.updateAppointment(appointment: appointment,
                                                clientName: clientName,
                                                startTime: startTime,
                                                endTime: endTime,
                                                employee: employee,
                                                services: services)
    }
}
