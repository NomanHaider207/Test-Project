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
    ) async throws -> Appointmemts

    func fetchAppointments() async throws -> [Appointmemts]
    func deleteAppointment(_ appointment: Appointmemts) async throws
    func fetchAppointmentModels() async -> Result<[AppointmentModel], Error>
    func fetchAppointmentEntity(by id: UUID) async throws -> Appointmemts
    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async throws -> Bool
    func updateAppointment(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async
}

// MARK: - Concrete Implementation
final class DefaultAppointmentRepository: AppointmentRepositoryProtocol {
    
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createAppointment(
        clientName: String,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async throws -> Appointmemts {
        return try await context.perform {
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

    func fetchAppointments() async throws -> [Appointmemts] {
        return try await context.perform {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            return try self.context.fetch(request)
        }
    }

    func deleteAppointment(_ appointment: Appointmemts) async throws {
        try await context.perform {
            self.context.delete(appointment)
            try self.context.save()
        }
    }

    func fetchAppointmentModels() async -> Result<[AppointmentModel], Error> {
        do {
            let appointments = try await context.perform {
                let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
                let coreDataAppointments = try self.context.fetch(request)
                
                let models: [AppointmentModel] = coreDataAppointments.compactMap { appointment in
                    guard let clientName = appointment.clientName,
                          let startTime = appointment.startTime,
                          let endTime = appointment.endTime,
                          let employeeCore = appointment.employee,
                          let employeeName = employeeCore.name,
                          let employeeID = employeeCore.id else {
                        return nil
                    }

                    let employeeModel = EmployeeModel(id: employeeID, name: employeeName, services: [])

                    let appointmentServices: [ServiceModel] = (appointment.services?.allObjects as? [Services])?.compactMap { service in
                        guard let id = service.id, let title = service.title else { return nil }
                        return ServiceModel(id: id, title: title)
                    } ?? []

                    return AppointmentModel(
                        id: appointment.id ?? UUID(),
                        clientName: clientName,
                        startTime: startTime,
                        endTime: endTime,
                        employee: employeeModel,
                        services: appointmentServices
                    )
                }

                return models
            }

            return .success(appointments)
        } catch {
            return .failure(error)
        }
    }



    
    func fetchAppointmentEntity(by id: UUID) async throws -> Appointmemts {
        return try await context.perform {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let results = try self.context.fetch(request)
            return results.first!
        }
    }
    
    
    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async throws -> Bool {
        return try await context.perform {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "employee == %@", employee),
                NSPredicate(format: "startTime < %@ AND endTime > %@", endTime as NSDate, startTime as NSDate)
            ])

            let conflicts = try self.context.fetch(request)
            return !conflicts.isEmpty
        }
    }

    
    func updateAppointment(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async {
        do {
            let appointmentEntity = try await fetchAppointmentEntity(by: appointment.id)
            
            appointmentEntity.clientName = clientName
            appointmentEntity.startTime = startTime
            appointmentEntity.endTime = endTime
            appointmentEntity.employee = employee
            appointmentEntity.services = NSSet(array: services)
            
            try self.context.save()
        } catch {
            print("Failed to update appointment: \(error.localizedDescription)")
        }
    }

}
