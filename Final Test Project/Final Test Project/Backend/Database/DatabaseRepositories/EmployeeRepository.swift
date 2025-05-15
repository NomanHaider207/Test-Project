//
//  EmployeeRepository.swift
//  Final Test Project
//
//  Created by Dev on 5/7/25.
//

import Foundation
import CoreData

// MARK: - Protocol
protocol EmployeeRepositoryProtocol {
    func createEmployee(name: String, services: [Services]) async -> Result<Employees, Error>
    func fetchEmployees() async -> Result<[Employees], Error>
    func fetchEmployeeModels() async -> Result<[EmployeeModel], Error>
    func fetchServices(for employeeId: UUID) async -> Result<[ServiceModel], Error>
    func fetchEmployeeEntity(by id: UUID) async -> Result<Employees, Error>
    func deleteEmployee(_ employee: Employees) async -> Result<Void, Error>
}

// MARK: - Concrete Implementation
class DefaultEmployeeRepository: EmployeeRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createEmployee(name: String, services: [Services]) async -> Result<Employees, Error> {
        do {
            let employee = Employees(context: context)
            employee.id = UUID()
            employee.name = name
            employee.addToServices(NSSet(array: services))
            try await saveContext()
            return .success(employee)
        } catch {
            return .failure(error)
        }
    }

    func fetchEmployees() async -> Result<[Employees], Error> {
        do {
            let request: NSFetchRequest<Employees> = Employees.fetchRequest()
            let employees = try context.fetch(request)
            return .success(employees)
        } catch {
            return .failure(error)
        }
    }

    func fetchEmployeeModels() async -> Result<[EmployeeModel], Error> {
        switch await fetchEmployees() {
        case .success(let employees):
            let models = employees.compactMap { employee -> EmployeeModel? in
                guard let id = employee.id, let name = employee.name else { return nil }
                return EmployeeModel(id: id, name: name, services: [])
            }
            return .success(models)
        case .failure(let error):
            return .failure(error)
        }
    }

    func fetchServices(for employeeId: UUID) async -> Result<[ServiceModel], Error> {
        let request: NSFetchRequest<Employees> = Employees.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        request.fetchLimit = 1
        request.relationshipKeyPathsForPrefetching = ["services"]

        do {
            let employees = try context.fetch(request)
            guard let employee = employees.first, let servicesSet = employee.services as? Set<Services> else {
                return .failure(NSError(domain: "EmployeeNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Employee not found or has no services."]))
            }

            let serviceModels = servicesSet.map {
                ServiceModel(id: $0.id ?? UUID(), title: $0.title ?? "")
            }
            return .success(serviceModels)
        } catch {
            return .failure(error)
        }
    }

    func fetchEmployeeEntity(by id: UUID) async -> Result<Employees, Error> {
        let request: NSFetchRequest<Employees> = Employees.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            guard let employee = try context.fetch(request).first else {
                return .failure(NSError(domain: "EmployeeNotFound", code: 404, userInfo: nil))
            }
            return .success(employee)
        } catch {
            return .failure(error)
        }
    }

    func deleteEmployee(_ employee: Employees) async -> Result<Void, Error> {
        do {
            context.delete(employee)
            try await saveContext()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func saveContext() async throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
