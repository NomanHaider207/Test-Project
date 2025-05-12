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
        appointmentDate: Date,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async throws -> Appointmemts

    func fetchAppointments() async throws -> [Appointmemts]
    func deleteAppointment(_ appointment: Appointmemts) async throws
    func fetchAppointmentModels() async throws -> [AppointmentModel]
    func fetchAppointmentEntity(by id: UUID) async throws -> Appointmemts
    func hasConflict(for employee: Employees, on date: Date, startTime: Date, endTime: Date) async throws -> Bool
}

// MARK: - Concrete Implementation
final class DefaultAppointmentRepository: AppointmentRepositoryProtocol {
    
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createAppointment(
        clientName: String,
        appointmentDate: Date,
        startTime: Date,
        endTime: Date,
        employee: Employees,
        services: [Services]
    ) async throws -> Appointmemts {
        return try await context.perform {
            let appointment = Appointmemts(context: self.context)
            appointment.id = UUID()
            appointment.clientName = clientName
            appointment.appointmentDate = appointmentDate
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

    func fetchAppointmentModels() async throws -> [AppointmentModel] {
        return try await context.perform {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()
            let coreDataAppointments = try self.context.fetch(request)

            return coreDataAppointments.compactMap { appointment in
                guard let clientName = appointment.clientName,
                      let appointmentDate = appointment.appointmentDate,
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
                    appointmentDate: appointmentDate,
                    startTime: startTime,
                    endTime: endTime,
                    employee: employeeModel,
                    services: appointmentServices
                )
            }
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
    
    
    func hasConflict(for employee: Employees, on date: Date, startTime: Date, endTime: Date) async throws -> Bool {
        return try await context.perform {
            let request: NSFetchRequest<Appointmemts> = Appointmemts.fetchRequest()

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "employee == %@", employee),
                NSPredicate(format: "appointmentDate >= %@ AND appointmentDate < %@", startOfDay as NSDate, endOfDay as NSDate),
                NSPredicate(format: "(startTime < %@ AND endTime > %@)", endTime as NSDate, startTime as NSDate)
            ])

            let conflicts = try self.context.fetch(request)
            return !conflicts.isEmpty
        }
    }


}
