//
//  AppointmentMode.swift
//  Final Test Project
//
//  Created by Dev  on 5/7/25.
//

import Foundation

// MARK: - Service
struct ServiceModel: Identifiable {
    var id: UUID
    var title: String
}

// MARK: - Employee
struct EmployeeModel: Identifiable {
    var id: UUID
    var name: String
    var services: [ServiceModel]
}

// MARK: - Appointment
struct AppointmentModel: Identifiable {
    var id: UUID
    var clientName: String
    var startTime: Date
    var endTime: Date
    var employee: EmployeeModel
    var services: [ServiceModel]
}
