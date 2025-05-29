//
//  CoreDataManager.swift
//  Final Test Project
//
//  Created by Dev  on 5/27/25.
//

import Foundation
import CoreData

// MARK: - Error Enum
enum CoreDataError: Error, LocalizedError {
    case entityNotFound(String)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case batchDeleteFailed(Error)
    case updateFailed(Error)

    var errorDescription: String? {
        switch self {
        case .entityNotFound(let name):
            return "Entity not found: \(name)"
        case .saveFailed(let error),
             .fetchFailed(let error),
             .deleteFailed(let error),
             .batchDeleteFailed(let error),
             .updateFailed(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - CoreDataManager
final class CoreDataManager {
    
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Final_Test_Project")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error.localizedDescription)")
            }
        }
        return container
    }()

    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    lazy var readOnlyContext: NSManagedObjectContext = {
          let context = persistentContainer.newBackgroundContext()
          context.automaticallyMergesChangesFromParent = true

          // Merge changes from main context saves into background context
          NotificationCenter.default.addObserver(
              forName: .NSManagedObjectContextDidSave,
              object: mainContext,
              queue: nil
          ) { [weak context] notification in
              context?.perform {
                  context?.mergeChanges(fromContextDidSave: notification)
              }
          }

          // Merge changes from background context saves into main context
          NotificationCenter.default.addObserver(
              forName: .NSManagedObjectContextDidSave,
              object: context,
              queue: nil
          ) { [weak self] notification in
              self?.mainContext.perform {
                  self?.mainContext.mergeChanges(fromContextDidSave: notification)
              }
          }
          return context
      }()
    
    


    private init() {}

    // MARK: - Save
    func save(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? mainContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
            ctx.refreshAllObjects()
        } catch {
            throw CoreDataError.saveFailed(error)
        }
    }

    // MARK: - Create
    func create<T: NSManagedObject>(entity: T.Type, in context: NSManagedObjectContext? = nil) throws -> T {
        let ctx = context ?? mainContext
        let name = String(describing: T.self)
        guard let entityDesc = NSEntityDescription.entity(forEntityName: name, in: ctx) else {
            throw CoreDataError.entityNotFound(name)
        }
        return T(entity: entityDesc, insertInto: ctx)
    }

    // MARK: - Fetch
    func fetch<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        in context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        let ctx = context ?? readOnlyContext
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try ctx.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    // MARK: - Delete
    func delete(_ objectID: NSManagedObjectID, in context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? mainContext
        let object = try ctx.existingObject(with: objectID)
        ctx.delete(object)
        try save(context: ctx)
    }

    // MARK: - Update
    func update(object: NSManagedObject, in context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? mainContext
        guard object.managedObjectContext == ctx else {
            throw CoreDataError.updateFailed(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mismatched context"]))
        }
        try save(context: ctx)
    }
}

