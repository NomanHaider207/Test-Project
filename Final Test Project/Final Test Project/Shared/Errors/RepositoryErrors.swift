//
//  RepositoryErrors.swift
//  Final Test Project
//
//  Created by Dev  on 5/28/25.
//

import Foundation

enum RepositoryError: Error, LocalizedError {
    case coreData(Error)
    case notFound(entity: String)
    case conflict(reason: String)
    case invalidData(reason: String)

    var errorDescription: String? {
        switch self {
        case .coreData(let error): return "Core Data error: \(error.localizedDescription)"
        case .notFound(let entity): return "\(entity) was not found."
        case .conflict(let reason): return "Conflict: \(reason)"
        case .invalidData(let reason): return "Invalid data: \(reason)"
        }
    }
}

