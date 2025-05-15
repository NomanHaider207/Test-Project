import Foundation

// MARK: - NetworkManager
class NetworkManager {

    private let appointmentRepo: AppointmentRepositoryProtocol
    private let employeeRepo: EmployeeRepositoryProtocol
    private let serviceRepo: ServiceRepositoryProtocol

    init(appointmentRepo: AppointmentRepositoryProtocol,
         employeeRepo: EmployeeRepositoryProtocol,
         serviceRepo: ServiceRepositoryProtocol) {
        self.appointmentRepo = appointmentRepo
        self.employeeRepo = employeeRepo
        self.serviceRepo = serviceRepo
    }

    // MARK: - Employees
    func getEmployees() async -> Result<[EmployeeModel], Error> {
        await employeeRepo.fetchEmployeeModels()
    }

    func getEmployee(by id: UUID) async -> Result<Employees, Error> {
        await employeeRepo.fetchEmployeeEntity(by: id)
    }

    func getEmployeeServices(for id: UUID) async -> Result<[ServiceModel], Error> {
        await employeeRepo.fetchServices(for: id)
    }

    // MARK: - Services
    func getServices(by ids: [UUID]) async -> Result<[Services], Error> {
        await serviceRepo.fetchServiceEntities(by: ids)
    }

    func getAllServices() async -> Result<[ServiceModel], Error> {
        await serviceRepo.fetchServicesModel()
    }

    // MARK: - Appointments
    func getAppointments() async -> Result<[AppointmentModel], Error> {
        await appointmentRepo.fetchAppointmentModels()
    }

    func getAppointment(by id: UUID) async -> Result<Appointmemts, Error> {
        await appointmentRepo.fetchAppointmentEntity(by: id)
    }

    func addAppointment(clientName: String,
                        startTime: Date,
                        endTime: Date,
                        employee: Employees,
                        services: [Services]) async -> Result<Bool, Error> {
        let conflictResult = await appointmentRepo.hasConflict(for: employee, startTime: startTime, endTime: endTime)

        switch conflictResult {
        case .success(let hasConflict):
            if hasConflict {
                NotificationCenter.default.post(name: NSNotification.Name("AppointmentConflict"), object: nil)
                return .success(false)
            }
            return await appointmentRepo.createAppointment(
                clientName: clientName,
                startTime: startTime,
                endTime: endTime,
                employee: employee,
                services: services
            ).map { _ in true }
        case .failure(let error):
            return .failure(error)
        }
    }

    func updateAppointment(appointment: AppointmentModel,
                           clientName: String,
                           startTime: Date,
                           endTime: Date,
                           employee: Employees,
                           services: [Services]) async -> Result<Void, Error> {
        await appointmentRepo.updateAppointment(
            appointment: appointment,
            clientName: clientName,
            startTime: startTime,
            endTime: endTime,
            employee: employee,
            services: services
        )
    }

    func removeAppointment(_ appointment: Appointmemts) async -> Result<Void, Error> {
        await appointmentRepo.deleteAppointment(appointment)
    }

    func checkConflict(employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, Error> {
        await appointmentRepo.hasConflict(for: employee, startTime: startTime, endTime: endTime)
    }
}
