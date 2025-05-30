
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
    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Bool, RepositoryError>
    func fetchAppointments() async -> Result<[Appointments], RepositoryError>
    func deleteAppointment(_ appointment: Appointments) async -> Result<Bool, RepositoryError>
    func fetchAppointmentById(by id: UUID, in ctx: NSManagedObjectContext?) async -> Result<Appointments, RepositoryError>
    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, RepositoryError>
    func updateAppointment(
        with data: Appointments,
        newClientName: String,
        newStartTime: Date,
        newEndTime: Date,
        selectedEmployee: Employees,
        selectedServices: [Services]
    ) async -> Result<Bool, RepositoryError> 
}

// MARK: - Concrete Implementation
final class DefaultAppointmentRepository: AppointmentRepositoryProtocol {

    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Bool, RepositoryError> {
    
        let conflictResult = await hasConflict(for: employee, startTime: startTime, endTime: endTime)

        switch conflictResult {
        case .failure(let error):
            return .failure(.coreData(error))
        case .success(true):
            return .failure(.conflict(reason: "Employee Already has appointment as this time."))
        case .success(false):
            do {
                let appointment = try CoreDataManager.shared.create(entity: Appointments.self)
                appointment.id = UUID()
                appointment.clientName = clientName
                appointment.employee = employee
                appointment.startTime = startTime
                appointment.endTime = endTime
                appointment.services = NSSet(array: services)
                
                try CoreDataManager.shared.save()
                
                return .success(true)
            } catch {
                return .failure(.coreData(error))
            }
        }
    }

    func fetchAppointments() async -> Result<[Appointments], RepositoryError> {
        do {
            let appointments = try CoreDataManager.shared.fetch(entity: Appointments.self)
            return .success(appointments)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func deleteAppointment(_ appointment: Appointments) async -> Result<Bool, RepositoryError> {
        do {
            try CoreDataManager.shared.delete(appointment.objectID)
            return .success(true)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func fetchAppointmentById(by id: UUID, in ctx: NSManagedObjectContext? = nil) async -> Result<Appointments, RepositoryError> {
        let context = ctx ?? CoreDataManager.shared.readOnlyContext
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let appointments = try CoreDataManager.shared.fetch(entity: Appointments.self, predicate: predicate, in: context)
            guard let appointment = appointments.first else {
                return .failure(.notFound(entity: "Appointment"))
            }
            return .success(appointment)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, RepositoryError> {
        let context = CoreDataManager.shared.readOnlyContext
        return await context.perform {
            do {
                let request: NSFetchRequest<Appointments> = Appointments.fetchRequest()
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "employee == %@", employee),
                    NSPredicate(format: "startTime < %@ AND endTime > %@", endTime as NSDate, startTime as NSDate)
                ])
                let results = try context.fetch(request)
                return .success(!results.isEmpty)
            } catch {
                return .failure(.coreData(error))
            }
        }
    }

    func updateAppointment(
        with data: Appointments,
        newClientName: String,
        newStartTime: Date,
        newEndTime: Date,
        selectedEmployee: Employees,
        selectedServices: [Services]
    ) async -> Result<Bool, RepositoryError> {
        guard let id = data.id else {
            return .failure(.notFound(entity: "Appointment"))
        }

        let mainContext = CoreDataManager.shared.mainContext
        let fetchResult = await fetchAppointmentById(by: id, in: mainContext)

        switch fetchResult {
        case .failure(let error):
            return .failure(error)

        case .success(let existingAppointment):
            do {
                let employeeId = selectedEmployee.objectID
                guard let employeeInMainContext = mainContext.object(with: employeeId) as? Employees else {
                    return .failure(.notFound(entity: "Employee"))
                }

                let servicesInMainContext = selectedServices.compactMap {
                    mainContext.object(with: $0.objectID) as? Services
                }

                // 🔥 Finally assign values inside main context
                existingAppointment.clientName = newClientName
                existingAppointment.startTime = newStartTime
                existingAppointment.endTime = newEndTime
                existingAppointment.employee = employeeInMainContext
                existingAppointment.services = NSSet(array: servicesInMainContext)
                
                try CoreDataManager.shared.update(object: existingAppointment)
                return .success(true)
            } catch {
                return .failure(.coreData(error))
            }
        }
    }



}
