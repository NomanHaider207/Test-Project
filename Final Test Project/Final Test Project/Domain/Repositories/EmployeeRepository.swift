import Foundation
import CoreData


// MARK: - Protocol
protocol EmployeeRepositoryProtocol {
    func fetchEmployees() async -> Result<[Employees], RepositoryError>
    func fetchServices(for employeeId: UUID) async -> Result<[Services], RepositoryError>
    func fetchEmployeeById(by id: UUID) async -> Result<Employees, RepositoryError>
    func createDummyEmployeesAndServices() async
}

class DefaultEmployeeRepository: EmployeeRepositoryProtocol {
    let context = CoreDataManager.shared.readOnlyContext

    func fetchEmployees() async -> Result<[Employees], RepositoryError> {
        do {
            var employees = try CoreDataManager.shared.fetch(entity: Employees.self, in: context)
            
            // Create the "All" employee
            if let entityDescription = NSEntityDescription.entity(forEntityName: "Employees", in: context) {
                        let allEmployee = Employees(entity: entityDescription, insertInto: nil)
                        allEmployee.id = nil
                        allEmployee.name = "All"
                        employees.insert(allEmployee, at: 0)
            }
            
            return .success(employees)
        } catch {
            return .failure(.coreData(error))
        }
    }


    func fetchServices(for employeeId: UUID) async -> Result<[Services], RepositoryError> {
        let predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        do {
            let employees = try CoreDataManager.shared.fetch(entity: Employees.self, predicate: predicate, in: context)
            guard let employee = employees.first else {
                return .failure(.notFound(entity: "Employee"))
            }

            guard let services = employee.services?.allObjects as? [Services], !services.isEmpty else {
                return .failure(.notFound(entity: "Employee Services"))
            }
            return .success(services)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func fetchEmployeeById(by id: UUID) async -> Result<Employees, RepositoryError> {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let employees = try CoreDataManager.shared.fetch(entity: Employees.self, predicate: predicate, in: context)
            guard let employee = employees.first else {
                return .failure(.notFound(entity: "Employee"))
            }
            return .success(employee)
        } catch {
            return .failure(.coreData(error))
        }
    }
    
    func createDummyEmployeesAndServices() async {
        let context = CoreDataManager.shared.mainContext

        // Create dummy services
        let service1 = Services(context: context)
        service1.id = UUID()
        service1.title = "Manicure"

        let service2 = Services(context: context)
        service2.id = UUID()
        service2.title = "Pedicure"

        // Create dummy employee and set relationship
        let employee1 = Employees(context: context)
        employee1.id = UUID()
        employee1.name = "Waris"
        employee1.services = NSSet(array: [service1, service2])

        do {
            try CoreDataManager.shared.save()
            print("Dummy employee and services saved successfully.")
        } catch {
            print("Failed to save dummy data: \(error)")
        }
    }
}

