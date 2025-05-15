
//
//  AppointmentRepository.swift
//  Final Test Project
//
//  Created by Dev on 5/7/25.
//

import Foundation
import CoreData

// MARK: - Protocol
protocol AppointmentRepositoryProtocol {
    func createAppointment(
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async -> Result<Appointmemts, Error>

    func fetchAppointments() async -> Result<[Appointmemts], Error>
    func deleteAppointment(_ appointment: Appointmemts) async -> Result<Void, Error>
    func fetchAppointmentModels() async -> Result<[AppointmentModel], Error>
    func fetchAppointmentEntity(by id: UUID) async -> Result<Appointmemts, Error>
    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, Error>
    func updateAppointment(
        appointment: AppointmentModel,
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async -> Result<Void, Error>
}

// MARK: - Concrete Implementation
final class DefaultAppointmentRepository: AppointmentRepositoryProtocol {
    
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Helper for reducing boilerplate
    private func performResult<T>(_ block: @escaping () throws -> T) async -> Result<T, Error> {
        await context.perform {
            Result(catching: block)
        }
    }

    // MARK: - CoreData Methods
    func createAppointment(
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async -> Result<Appointmemts, Error> {
        await performResult {
            let appointment = Appointmemts(context: self.context)
            appointment.id = UUID()
            appointment.clientName = clientName
            appointment.startTime = startTime
            appointment.endTime = endTime
            appointment.employee = employee
            appointment.addToServices(NSSet(array: services))
            try self.context.save()
            return appointment
        }
    }

    func fetchAppointments() async -> Result<[Appointmemts], Error> {
        await performResult {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            return try self.context.fetch(request)
        }
    }

    func deleteAppointment(_ appointment: Appointmemts) async -> Result<Void, Error> {
        await performResult {
            self.context.delete(appointment)
            try self.context.save()
        }
    }

    func fetchAppointmentModels() async -> Result<[AppointmentModel], Error> {
        await performResult {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            let results = try self.context.fetch(request)
            
            return results.compactMap { appointment in
                guard let clientName = appointment.clientName,
                      let startTime = appointment.startTime,
                      let endTime = appointment.endTime,
                      let employee = appointment.employee,
                      let empName = employee.name,
                      let empId = employee.id else {
                    return nil
                }

                let services: [ServiceModel] = (appointment.services?.allObjects as? [Services])?.compactMap {
                    guard let id = $0.id, let title = $0.title else { return nil }
                    return ServiceModel(id: id, title: title)
                } ?? []

                return AppointmentModel(
                    id: appointment.id ?? UUID(),
                    clientName: clientName,
                    startTime: startTime,
                    endTime: endTime,
                    employee: EmployeeModel(id: empId, name: empName, services: []),
                    services: services
                )
            }
        }
    }

    func fetchAppointmentEntity(by id: UUID) async -> Result<Appointmemts, Error> {
        await performResult {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let appointment = try self.context.fetch(request).first else {
                throw NSError(domain: "AppointmentRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Appointment not found"])
            }
            return appointment
        }
    }

    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, Error> {
        await performResult {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "employee == %@", employee),
                NSPredicate(format: "startTime < %@ AND endTime > %@", endTime as NSDate, startTime as NSDate)
            ])
            return try !self.context.fetch(request).isEmpty
        }
    }

    func updateAppointment(
        appointment: AppointmentModel,
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async -> Result<Void, Error> {
        let entityResult = await fetchAppointmentEntity(by: appointment.id)
        
        switch entityResult {
        case .success(let appointmentEntity):
            return await performResult {
                appointmentEntity.clientName = clientName
                appointmentEntity.startTime = startTime
                appointmentEntity.endTime = endTime
                appointmentEntity.employee = employee
                appointmentEntity.services = NSSet(array: services)
                try self.context.save()
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }

}
