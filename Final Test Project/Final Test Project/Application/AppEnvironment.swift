//
//  AppEnvironment.swift
//  Final Test Project
//
//  Created by Dev  on 5/8/25.
//

import Foundation
import UIKit

// if I make the RepoManager Singleton I am unable to pass those repos to the Network Manager I have to declared them in the class and for the 
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


