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

    let viewModel: DefaultViewModel

    @MainActor
    private init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let appointmentRepo = DefaultAppointmentRepository(context: context)
        let employeeRepo = DefaultEmployeeRepository(context: context)
        let servicesRepo = DefaultServiceRepository(context: context)
        self.viewModel = DefaultViewModel(repository: appointmentRepo, employeesRepository: employeeRepo, servicesRepository: servicesRepo)
    }
}


