//
//  AppEnvironment.swift
//  Final Test Project
//
//  Created by Dev  on 5/8/25.
//

import Foundation
import UIKit

@MainActor
final class AppEnvironment {
    static let shared: AppEnvironment = {
        return AppEnvironment()
    }()
    
    let networkManger: RepositoryManager

    @MainActor
    private init() {
        let appointmentRepo = DefaultAppointmentRepository()
        let employeeRepo = DefaultEmployeeRepository()
        let servicesRepo = DefaultServiceRepository()
        self.networkManger = RepositoryManager(appointmentRepo: appointmentRepo, employeeRepo: employeeRepo, serviceRepo: servicesRepo)
    }
}


