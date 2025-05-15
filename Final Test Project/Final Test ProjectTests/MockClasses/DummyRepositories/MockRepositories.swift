//
//  MockError.swift
//  Final Test Project Tests
//
//  Created by Dev on 5/15/25.
//

import Foundation
@testable import Final_Test_Project

// MARK: - Mock Error
enum MockError: Error {
    case generic
    case employeeNotFound
}

// MARK: - DummyAppointmentRepo
class DummyAppointmentRepo: AppointmentRepositoryProtocol {
    
       func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Final_Test_Project.Employees, services: [Final_Test_Project.Services]) async -> Result<Final_Test_Project.Appointmemts, Error> {
           .failure(MockError.generic)
       }
    
    func fetchAppointments() async -> Result<[Final_Test_Project.Appointmemts], any Error> {
        .success([])
    }
    
    func fetchAppointmentModels() async -> Result<[AppointmentModel], Error> {
        .success([])
    }

    func fetchAppointmentEntity(by id: UUID) async -> Result<Appointmemts, Error> {
        .failure(MockError.generic)
    }

    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Void, Error> {
        .success(())
    }

    func updateAppointment(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Void, Error> {
        .success(())
    }

    func deleteAppointment(_ appointment: Appointmemts) async -> Result<Void, Error> {
        .success(())
    }

    func hasConflict(for employee: Employees, startTime: Date, endTime: Date) async -> Result<Bool, Error> {
        .success(false)
    }
}

// MARK: - DummyEmployeeRepo
class DummyEmployeeRepo: EmployeeRepositoryProtocol {
    func fetchEmployeeModels() async -> Result<[EmployeeModel], Error> {
        .success([])
    }

    func fetchEmployeeEntity(by id: UUID) async -> Result<Employees, Error> {
        .failure(MockError.generic)
    }

    func fetchServices(for id: UUID) async -> Result<[ServiceModel], Error> {
        .success([])
    }

    func createEmployee(name: String, services: [Services]) async -> Result<Employees, Error> {
        .failure(MockError.generic)
    }

    func fetchEmployees() async -> Result<[Employees], Error> {
        .success([])
    }

    func deleteEmployee(_ employee: Employees) async -> Result<Void, Error> {
        .success(())
    }
}

// MARK: - DummyServiceRepo
class DummyServiceRepo: ServiceRepositoryProtocol {
    func fetchServiceEntities(by ids: [UUID]) async -> Result<[Services], Error> {
        .success([])
    }

    func fetchServicesModel() async -> Result<[ServiceModel], Error> {
        .success([])
    }

    func createService(title: String) async -> Result<Services, Error> {
        .failure(MockError.generic)
    }

    func fetchServices() async -> Result<[Services], Error> {
        .success([])
    }

    func deleteService(_ service: Services) async -> Result<Void, Error> {
        .success(())
    }
}
