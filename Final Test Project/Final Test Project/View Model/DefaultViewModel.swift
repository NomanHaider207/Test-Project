import Foundation

protocol ViewModelDelegate: AnyObject {
    func didFailWithError(_ error: Error)
}

@MainActor
final class DefaultViewModel: ObservableObject {

    // MARK: - Dependencies
    private let appointmentRepository: AppointmentRepositoryProtocol
    private let employeesRepository: EmployeeRepositoryProtocol
    private let servicesRepository: ServiceRepositoryProtocol
    weak var delegate: ViewModelDelegate?

    // MARK: - Published Properties
    @Published private(set) var appointments: [AppointmentModel] = []
    @Published private(set) var employees: [EmployeeModel] = []
    @Published var selectedDate: Date = Date() {
        didSet { filterAppointments() }
    }
    @Published var selectedEmployeeId: UUID? = nil {
        didSet { filterAppointments() }
    }

    // MARK: - Private Properties
    private(set) var allAppointments: [AppointmentModel] = []

    // MARK: - Initializer
    init(
        repository: AppointmentRepositoryProtocol,
        employeesRepository: EmployeeRepositoryProtocol,
        servicesRepository: ServiceRepositoryProtocol
    ) {
        self.appointmentRepository = repository
        self.employeesRepository = employeesRepository
        self.servicesRepository = servicesRepository
    }

    // MARK: - Load Methods
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
        let result = await appointmentRepository.fetchAppointmentModels()
        switch result {
        case .success(let appointments):
            self.allAppointments = appointments
            filterAppointments()
        case .failure(let error):
            delegate?.didFailWithError(error)
        }
    }

    // MARK: - Create / Update / Delete
    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        do {
            let hasConflict = try await appointmentRepository.hasConflict(for: employee, startTime: startTime, endTime: endTime)
            if hasConflict {
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AppointmentConflict"), object: nil)
                }
                return
            }
            _ = try await appointmentRepository.createAppointment(clientName: clientName, startTime: startTime, endTime: endTime, employee: employee, services: services)
            await loadAppointments()
        } catch {
            print("Failed to create appointment:", error)
        }
    }

    func updateAppointmentModel(
        appointment: AppointmentModel,
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async {
        await appointmentRepository.updateAppointment(
            appointment: appointment,
            clientName: clientName,
            startTime: startTime,
            endTime: endTime,
            employee: employee,
            services: services
        )
    }

    func deleteAppointment(_ appointment: Appointmemts) async {
        do {
            try await appointmentRepository.deleteAppointment(appointment)
            await loadAppointments()
        } catch {
            print("Failed to delete appointment:", error)
        }
    }

    // MARK: - Fetch Entity Methods
    func fetchAppointmentById(by id: UUID) async -> Appointmemts? {
        do {
            return try await appointmentRepository.fetchAppointmentEntity(by: id)
        } catch {
            print("Failed to fetch appointment with ID \(id):", error)
            return nil
        }
    }

    func fetchEmployeeEntity(by id: UUID) async -> Employees? {
        let result = await employeesRepository.fetchEmployeeEntity(by: id)
        switch result {
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

    func fetchServices() async -> [ServiceModel] {
        let result = await servicesRepository.fetchServicesModel()
        switch result {
        case .success(let services):
            return services
        case .failure(let error):
            delegate?.didFailWithError(error)
            return []
        }
    }

    func getServicesForSelectedEmployee() async -> [ServiceModel] {
        guard let selectedId = selectedEmployeeId else { return [] }

        let result = await employeesRepository.fetchServices(for: selectedId)
        switch result {
        case .success(let serviceModels):
            return serviceModels
        case .failure(let error):
            delegate?.didFailWithError(error)
            return []
        }
    }

    // MARK: - Filter Appointments
    private func filterAppointments() {
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
        guard let endOfSelectedDate = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDate) else { return }

        self.appointments = allAppointments.filter { appointment in
            let isOverlapping = appointment.startTime < endOfSelectedDate && appointment.endTime >= startOfSelectedDate
            let matchesEmployee = selectedEmployeeId == nil || appointment.employee.id == selectedEmployeeId
            return isOverlapping && matchesEmployee
        }
    }
}
