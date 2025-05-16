//
//  DefaultViewModelTest.swift
//  Final Test ProjectTests
//
//  Created by Dev  on 5/15/25.
//

import XCTest
@testable import Final_Test_Project

@MainActor
final class DefaultViewModelTest: XCTestCase {
    private var sut: DefaultViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = DefaultViewModel(networkManager: MockNetworkManager())
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    
    // MARK: - Test Cases of function formattedTime(for appointment: AppointmentModel) -> String to check all condition
    func testFormatAppointmentTime(){
        
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(2*60*60)
        let employee = EmployeeModel(id: UUID(), name: "Noman", services: [])
        let services = [
            ServiceModel(id: UUID(), title: "Haircut"),
            ServiceModel(id: UUID(), title: "Massage")
        ]
        
        
        let appointment = AppointmentModel(id: UUID(), clientName: "Ibrahim", startTime: startDate, endTime: endDate, employee: employee, services: services)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        
        let formattedDate = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        
        XCTAssertEqual(sut.formattedTime(for: appointment), formattedDate)
    }
    
    // MARK: - Test Cases of function formatServicesList(_ services: [ServiceModel]) -> String to check all condition
    func testFormatServicesList_Services_ReturnsString(){
        let services: [ServiceModel] = [ ServiceModel(id: UUID(), title: "Haircut"), ServiceModel(id: UUID(), title: "Head Massage")]
        let formattedServicesString = "Haircut, Head Massage"
        XCTAssertEqual(sut.formatServicesList(services), formattedServicesString)
    }
    
    func testFormatServicesList_NoServices_ReturnsEmptyString(){
        let services: [ServiceModel] = []
        let formattedServicesString = ""
        XCTAssertEqual(sut.formatServicesList(services), formattedServicesString)
    }
    
    
    // MARK: - Test Cases of function isAllEmployeesOption(at index: Int) -> Bool to check all condition
    func testIsAllEmployeesOption_WithAllName_ReturnsTrue() {
        let allOption = EmployeeModel(id: UUID(), name: "All", services: [])
        sut.employees = [allOption]
        
        let result = sut.isAllEmployeesOption(at: 0)
        
        XCTAssertTrue(result)
    }

    func testIsAllEmployeesOption_WithOtherName_ReturnsFalse() {
        let employee = EmployeeModel(id: UUID(), name: "John", services: [])
        sut.employees = [employee]
        
        let result = sut.isAllEmployeesOption(at: 0)
        
        XCTAssertFalse(result)
    }

    func testIsAllEmployeesOption_WithOutOfBoundsIndex_ReturnsFalse() {
        sut.employees = []
        let result = sut.isAllEmployeesOption(at: 0)
        XCTAssertFalse(result)
    }
    
    // MARK: - Test Cases of function selectEmployee(at index: Int) to check all condition
    func testSelectEmployee_ValidIndex_RegularEmployee() {
        let employee = EmployeeModel(id: UUID(), name: "Noman", services: [])
        sut.employees = [employee]

        sut.selectEmployee(at: 0)

        XCTAssertEqual(sut.selectedEmployeeId, employee.id)
    }

    func testSelectEmployee_ValidIndex_AllEmployee() {
        let allEmployee = EmployeeModel(id: UUID(), name: "All", services: [])
        sut.employees = [allEmployee]

        sut.selectEmployee(at: 0)
        XCTAssertNil(sut.selectedEmployeeId)
    }

    func testSelectEmployee_IndexOutOfBounds_DoesNothing() {
        let employee = EmployeeModel(id: UUID(), name: "Noman Haider", services: [])
        sut.employees = [employee]
        sut.selectedEmployeeId = UUID()

        sut.selectEmployee(at: 1)
        
        XCTAssertNotNil(sut.selectedEmployeeId)
        XCTAssertNotEqual(sut.selectedEmployeeId, nil)
    }
    
    
    // MARK: - Test Cases of function filterAppointments() to check all condition
    func testFilterAppointments_ByDateOnly() {
        let mockDelegate = MockAppointmentViewModelDelegate()
        sut.delegate = mockDelegate

        let calendar = Calendar.current
        let today = Date()
        sut.selectedDate = today

        let startOfToday = calendar.startOfDay(for: today)
        let endOfToday = calendar.date(byAdding: .hour, value: 1, to: startOfToday)!

        let appointment = AppointmentModel(
            id: UUID(),
            clientName: "Test",
            startTime: startOfToday,
            endTime: endOfToday,
            employee: EmployeeModel(id: UUID(), name: "Noman", services: []),
            services: []
        )

        sut.allAppointments = [appointment]
        sut.selectedEmployeeId = nil

        sut.filterAppointments()

        XCTAssertEqual(sut.appointments.count, 1)
        XCTAssertTrue(mockDelegate.didUpdateDataCalled)
    }

    func testFilterAppointments_ByDateAndEmployee() {
        let mockDelegate = MockAppointmentViewModelDelegate()
        sut.delegate = mockDelegate

        let calendar = Calendar.current
        let today = Date()
        sut.selectedDate = today

        let employeeId = UUID()
        let matchingAppointment = AppointmentModel(
            id: UUID(),
            clientName: "Match",
            startTime: calendar.startOfDay(for: today),
            endTime: calendar.date(byAdding: .hour, value: 1, to: today)!,
            employee: EmployeeModel(id: employeeId, name: "Noman", services: []),
            services: []
        )

        let nonMatchingAppointment = AppointmentModel(
            id: UUID(),
            clientName: "No Match",
            startTime: calendar.startOfDay(for: today),
            endTime: calendar.date(byAdding: .hour, value: 1, to: today)!,
            employee: EmployeeModel(id: UUID(), name: "No Noman", services: []),
            services: []
        )

        sut.allAppointments = [matchingAppointment, nonMatchingAppointment]
        sut.selectedEmployeeId = employeeId

        sut.filterAppointments()

        XCTAssertEqual(sut.appointments.count, 1)
        XCTAssertEqual(sut.appointments.first?.clientName, "Match")
        XCTAssertTrue(mockDelegate.didUpdateDataCalled)
    }

    func testFilterAppointments_NoMatch() {
        let mockDelegate = MockAppointmentViewModelDelegate()
        sut.delegate = mockDelegate

        sut.selectedDate = Date()
        sut.selectedEmployeeId = UUID()

        sut.allAppointments = []

        sut.filterAppointments()

        XCTAssertTrue(sut.appointments.isEmpty)
        XCTAssertTrue(mockDelegate.didUpdateDataCalled)
    }

    
    // MARK: - Test Cases of function loadEmployees() to check all condition
    func testLoadEmployeesSuccess() async {
        let mockEmployees = [EmployeeModel(id: UUID(), name: "Noman", services: [])]
        let mockManager = MockNetworkManager(mockEmployeeModels: mockEmployees)
        let viewModel = DefaultViewModel(networkManager: mockManager)
        
        let delegate = MockAppointmentViewModelDelegate()
        viewModel.delegate = delegate

        await viewModel.loadEmployees()

        XCTAssertEqual(viewModel.employees.count, 2)
        XCTAssertEqual(viewModel.employees[1].name, "Noman")
        XCTAssertTrue(delegate.didUpdateDataCalled)
    }
    
    func testLoadEmployeeFailure() async {
        let mockManager = MockNetworkManager(shouldFail: true)
        let viewModel = DefaultViewModel(networkManager: mockManager)
        
        let delegate = MockAppointmentViewModelDelegate()
        viewModel.delegate = delegate
        
        await viewModel.loadEmployees()
        
        XCTAssertTrue(delegate.didFailWithErrorCalled)
    }


}
