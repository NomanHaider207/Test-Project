//
//  MockNetworkManager.swift
//  Final Test Project
//
//  Created by Dev  on 5/15/25.
//


import Foundation
@testable import Final_Test_Project

final class MockNetworkManager: NetworkManager {
    
    private let mockEmployeeModels: [EmployeeModel]
    private let mockServiceModels: [ServiceModel]
    private let mockEmployees: [UUID: Employees]
    private let mockServices: [UUID: Services]
    private let shouldConflict: Bool
    private let shouldFail: Bool

    init(
        mockEmployeeModels: [EmployeeModel] = [],
        mockServiceModels: [ServiceModel] = [],
        mockEmployees: [UUID: Employees] = [:],
        mockServices: [UUID: Services] = [:],
        shouldConflict: Bool = false,
        shouldFail: Bool = false
    ) {
        self.mockEmployeeModels = mockEmployeeModels
        self.mockServiceModels = mockServiceModels
        self.mockEmployees = mockEmployees
        self.mockServices = mockServices
        self.shouldConflict = shouldConflict
        self.shouldFail = shouldFail

        // We can inject dummy repos or use stubs for parent class init
        super.init(
            appointmentRepo: DummyAppointmentRepo(),
            employeeRepo: DummyEmployeeRepo(),
            serviceRepo: DummyServiceRepo()
        )
    }

    // MARK: - Override Functions for Testing

    override func getEmployees() async -> Result<[EmployeeModel], Error> {
        return shouldFail ? .failure(MockError.generic) : .success(mockEmployeeModels)
    }

    override func getEmployee(by id: UUID) async -> Result<Employees, Error> {
        guard !shouldFail, let employee = mockEmployees[id] else {
            return .failure(MockError.employeeNotFound)
        }
        return .success(employee)
    }

    override func getEmployeeServices(for id: UUID) async -> Result<[ServiceModel], Error> {
        return shouldFail ? .failure(MockError.generic) : .success(mockServiceModels)
    }

    override func getServices(by ids: [UUID]) async -> Result<[Services], Error> {
        let services = ids.compactMap { mockServices[$0] }
        return shouldFail ? .failure(MockError.generic) : .success(services)
    }

    override func addAppointment(clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Bool, Error> {
        if shouldFail {
            return .failure(MockError.generic)
        }
        if shouldConflict {
            NotificationCenter.default.post(name: NSNotification.Name("AppointmentConflict"), object: nil)
            return .success(false)
        }
        return .success(true)
    }

    override func updateAppointment(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Employees, services: [Services]) async -> Result<Void, Error> {
        return shouldFail ? .failure(MockError.generic) : .success(())
    }
}
