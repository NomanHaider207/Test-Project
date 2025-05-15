import Foundation
import CoreData

protocol ServiceRepositoryProtocol {
    func createService(title: String) async -> Result<Services, Error>
    func fetchServices() async -> Result<[Services], Error>
    func fetchServicesModel() async -> Result<[ServiceModel], Error>
    func deleteService(_ service: Services) async -> Result<Void, Error>
    func fetchServiceEntities(by ids: [UUID]) async -> Result<[Services], Error>
}

class DefaultServiceRepository: ServiceRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createService(title: String) async -> Result<Services, Error> {
        do {
            let service = Services(context: context)
            service.id = UUID()
            service.title = title
            try await saveContext()
            return .success(service)
        } catch {
            return .failure(error)
        }
    }

    func fetchServices() async -> Result<[Services], Error> {
        do {
            let request: NSFetchRequest<Services> = Services.fetchRequest()
            let services = try context.fetch(request)
            return .success(services)
        } catch {
            return .failure(error)
        }
    }

    func fetchServicesModel() async -> Result<[ServiceModel], Error> {
        switch await fetchServices() {
        case .success(let services):
            let models: [ServiceModel] = services.compactMap { service in
                guard let id = service.id, let title = service.title else { return nil }
                return ServiceModel(id: id, title: title)
            }
            return .success(models)
        case .failure(let error):
            return .failure(error)
        }
    }

    func fetchServiceEntities(by ids: [UUID]) async -> Result<[Services], Error> {
        do {
            let request: NSFetchRequest<Services> = Services.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            let result = try context.fetch(request)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    func deleteService(_ service: Services) async -> Result<Void, Error> {
        do {
            context.delete(service)
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
