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
    func fetchServices() async -> Result<[Services], RepositoryError>
    func fetchServicesById(by ids: [UUID]) async -> Result<[Services], RepositoryError>
}

// MARK: - Concrete Implementation
class DefaultServiceRepository: ServiceRepositoryProtocol {
    let context = CoreDataManager.shared.readOnlyContext
    
    func fetchServices() async -> Result<[Services], RepositoryError> {
        do {
            let services = try CoreDataManager.shared.fetch(entity: Services.self, in: context)
            return .success(services)
        } catch {
            return .failure(.coreData(error))
        }
    }
    
    func fetchServicesById(by ids: [UUID]) async -> Result<[Services], RepositoryError> {
        let predicate = NSPredicate(format: "id IN %@", ids)
        do {
            let services = try CoreDataManager.shared.fetch(entity: Services.self, predicate: predicate, in: context)
            return .success(services)
        } catch {
            return .failure(.coreData(error))
        }
    }
}
