//
//  ServiceRepository.swift
//  Final Test Project
//
//  Created by Dev on 5/7/25.
//

import Foundation
import CoreData

// MARK: - Protocol
protocol ServiceRepositoryProtocol {
    func createService(title: String) async throws -> Services
    func fetchServices() async throws -> [Services]
    func fetchServicesModel() async -> Result<[ServiceModel], Error>
    func deleteService(_ service: Services) async throws
    func fetchServiceEntities(by ids: [UUID]) async throws -> [Services] 
}

// MARK: - Concrete Implementation
class DefaultServiceRepository: ServiceRepositoryProtocol {
    
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createService(title: String) async throws -> Services {
        let service = Services(context: context)
        service.id = UUID()
        service.title = title
        try await saveContext()
        return service
    }

    func fetchServices() async throws -> [Services] {
        let request: NSFetchRequest<Services> = Services.fetchRequest()
        return try context.fetch(request)
    }
    
    func fetchServicesModel() async -> Result<[ServiceModel], Error> {
        do {
            let services = try await fetchServices()
            let models: [ServiceModel] = services.compactMap { service in
                guard let id = service.id, let title = service.title else { return nil }
                return ServiceModel(id: id, title: title)
            }
            return .success(models)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchServiceEntities(by ids: [UUID]) async throws -> [Services] {
        let request: NSFetchRequest<Services> = Services.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return try context.fetch(request)
    }

    func deleteService(_ service: Services) async throws {
        context.delete(service)
        try await saveContext()
    }

    private func saveContext() async throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
