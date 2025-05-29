import Foundation

// MARK: - RepositoryManager
class RepositoryManager {

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
    func getEmployees() async -> Result<[Employees], RepositoryError> {
        print("[Repository Services] - get Employee Function called.")
        return await employeeRepo.fetchEmployees()
    }
    
    func getEmployeeById(by id: UUID) async -> Result<Employees, RepositoryError> {
        print("[Repository Services] - get Employee by Id Function called.")
       return  await employeeRepo.fetchEmployeeById(by: id)
    }

    func getEmployeeServices(for id: UUID) async -> Result<[Services], RepositoryError> {
        await employeeRepo.fetchServices(for: id)
    }

    // MARK: - Services
    func getServices(by ids: [UUID]) async -> Result<[Services], RepositoryError> {
        print("[Repository Services] - get Services Function called.")
        return await serviceRepo.fetchServicesById(by: ids)
    }

    // MARK: - Appointments
    func getAllAppointments() async -> Result<[Appointments], RepositoryError> {
        print("[Repository Services] - get All Appointments Function called.")
        return await appointmentRepo.fetchAppointments()
    }


    func getAppointmentById(by id: UUID) async -> Result<Appointments, RepositoryError> {
        print("[Repository Services] - Get Appointment By Id Function called.")
        return await appointmentRepo.fetchAppointmentById(by: id, in: nil)
    }

    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Bool, RepositoryError> {
        print("[Repository Services] - Create Appointment Function called.")
        return await appointmentRepo.createAppointment(clientName: clientName, startTime: startTime, endTime: endTime, employee: employee, services: services)
    }
    
    func updateAppointment(
        with appointment: Appointments,
        newClientName: String,
        newStartTime: Date,
        newEndTime: Date,
        selectedEmployee: Employees,
        selectedServices: [Services]
    ) async -> Result<Bool, RepositoryError> {
        return await appointmentRepo.updateAppointment(
            with: appointment,
            newClientName: newClientName,
            newStartTime: newStartTime,
            newEndTime: newEndTime,
            selectedEmployee: selectedEmployee,
            selectedServices: selectedServices
        )
    }

    
    func deleteAppointment(_ appointment: Appointments) async -> Result<Bool, RepositoryError> {
        print("[Repository Services] - Delete Appointments Function called.")
        return await appointmentRepo.deleteAppointment(appointment)
    }
    
    func creatDummyData() async {
        await employeeRepo.createDummyEmployeesAndServices()
    }
}
