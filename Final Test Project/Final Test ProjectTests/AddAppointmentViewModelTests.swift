//
//  AddAppointmentViewModelTests.swift
//  Final Test Project
//
//  Created by Dev  on 5/14/25.
//


//
//  AddAppointmentViewModelTests.swift
//  Final Test ProjectTests
//
//  Created by Dev on 5/14/25.
//

import XCTest
@testable import Final_Test_Project

final class AddAppointmentViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: AddAppointmentViewModel!
    private var mockDefaultViewModel: MockDefaultViewModel!
    private var mockDelegate: MockViewModelDelegate!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        mockDefaultViewModel = MockDefaultViewModel()
        sut = AddAppointmentViewModel(defaultViewModel: mockDefaultViewModel)
        mockDelegate = MockViewModelDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockDefaultViewModel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Employee Selection Tests
    func testSelectEmployee_ShouldUpdateSelectedEmployee() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        
        // When
        sut.selectEmployee(at: 0)
        
        // Then
        XCTAssertEqual(sut.selectedEmployee?.id, "employee1")
        XCTAssertEqual(sut.selectedEmployee?.name, "John Doe")
        XCTAssertEqual(mockDefaultViewModel.selectedEmployeeId, "employee1")
    }
    
    func testResetSelectedEmployee_ShouldClearSelection() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        
        // When
        sut.resetSelectedEmployee()
        
        // Then
        XCTAssertNil(mockDefaultViewModel.selectedEmployeeId)
    }
    
    func testFilteredEmployees_ShouldReturnEmployeesExceptFirst() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        
        // When
        let result = sut.filteredEmployees
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "employee1")
        XCTAssertEqual(result[1].id, "employee2")
    }
    
    // MARK: - Date Management Tests
    func testUpdateStartTime_ShouldSetStartTimeAndResetEndTime() {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        
        // When
        let newStartDate = startDate.addingTimeInterval(1800) // 30 minutes later
        sut.updateStartTime(newStartDate)
        
        // Then
        XCTAssertEqual(sut.startDate, newStartDate)
        XCTAssertNil(sut.endDate, "End date should be reset when start date changes")
    }
    
    func testUpdateEndTime_ShouldSetEndTime() {
        // Given
        let startDate = Date()
        sut.updateStartTime(startDate)
        
        // When
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        sut.updateEndTime(endDate)
        
        // Then
        XCTAssertEqual(sut.endDate, endDate)
    }
    
    func testCanSetEndTime_WithValidEndTime_ShouldReturnTrue() {
        // Given
        let startDate = Date()
        sut.updateStartTime(startDate)
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        
        // When
        let result = sut.canSetEndTime(endDate)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testCanSetEndTime_WithInvalidEndTime_ShouldReturnFalse() {
        // Given
        let startDate = Date()
        sut.updateStartTime(startDate)
        let endDate = startDate.addingTimeInterval(-3600) // 1 hour earlier
        
        // When
        let result = sut.canSetEndTime(endDate)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateTimeRange_WhenBothDatesSet_ShouldCallDefaultViewModel() {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        mockDefaultViewModel.validateAppointmentInputResult = true
        
        // When
        let result = sut.validateTimeRange()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDefaultViewModel.validateAppointmentInputCallCount, 1)
        XCTAssertEqual(mockDefaultViewModel.lastValidatedStartTime, startDate)
        XCTAssertEqual(mockDefaultViewModel.lastValidatedEndTime, endDate)
    }
    
    func testValidateTimeRange_WhenDatesNotSet_ShouldReturnFalse() {
        // Given
        sut.updateStartTime(nil) // Force nil using private method
        
        // When
        let result = sut.validateTimeRange()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockDefaultViewModel.validateAppointmentInputCallCount, 0)
    }
    
    // MARK: - Service Selection Tests
    func testCanSelectServices_WithEmployeeSelected_ShouldReturnTrue() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        
        // When
        let result = sut.canSelectServices()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testCanSelectServices_WithNoEmployeeSelected_ShouldReturnFalse() {
        // Given - no employee selected
        
        // When
        let result = sut.canSelectServices()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testUpdateSelectedServices_ShouldSetServices() {
        // Given
        let services = createTestServices()
        
        // When
        sut.updateSelectedServices(services)
        
        // Then
        XCTAssertEqual(sut.selectedServices.count, 2)
        XCTAssertEqual(sut.selectedServices[0].id, "service1")
        XCTAssertEqual(sut.selectedServices[1].id, "service2")
    }
    
    func testLoadServicesForSelectedEmployee_ShouldFetchFromDefaultViewModel() async {
        // Given
        let services = createTestServices()
        mockDefaultViewModel.servicesForSelectedEmployee = services
        
        // When
        await sut.loadServicesForSelectedEmployee()
        
        // Then
        XCTAssertEqual(sut.availableServicesForEmployee.count, 2)
        XCTAssertEqual(sut.availableServicesForEmployee[0].id, "service1")
        XCTAssertEqual(sut.availableServicesForEmployee[1].id, "service2")
        XCTAssertTrue(sut.selectedServices.isEmpty, "Selected services should be reset")
    }
    
    // MARK: - Data Population Tests
    func testPopulateDataForEditing_ShouldSetAllValues() {
        // Given
        let appointment = createTestAppointment()
        
        // When
        sut.populateDataForEditing(with: appointment)
        
        // Then
        XCTAssertEqual(sut.clientName, "Test Client")
        XCTAssertEqual(sut.startDate, appointment.startTime)
        XCTAssertEqual(sut.endDate, appointment.endTime)
        XCTAssertEqual(sut.selectedEmployee?.id, "employee1")
        XCTAssertEqual(sut.selectedServices.count, 1)
        XCTAssertEqual(sut.selectedServices[0].id, "service1")
        XCTAssertEqual(mockDefaultViewModel.selectedEmployeeId, "employee1")
    }
    
    // MARK: - Text Formatting Tests
    func testFormattedStartTime_WithDateSet_ShouldReturnFormattedString() {
        // Given
        let date = createTestDate(year: 2025, month: 5, day: 15, hour: 10, minute: 30)
        sut.updateStartTime(date)
        
        // When
        let result = sut.formattedStartTime
        
        // Then
        // Note: This test depends on locale settings - adjust expected result if needed
        XCTAssertEqual(result, "May 15, 2025, 10:30 AM")
    }
    
    func testFormattedEndTime_WithDateSet_ShouldReturnFormattedString() {
        // Given
        let date = createTestDate(year: 2025, month: 5, day: 15, hour: 11, minute: 30)
        sut.updateEndTime(date)
        
        // When
        let result = sut.formattedEndTime
        
        // Then
        // Note: This test depends on locale settings - adjust expected result if needed
        XCTAssertEqual(result, "May 15, 2025, 11:30 AM")
    }
    
    func testSelectedServicesText_WithServicesSelected_ShouldReturnCommaSeparatedString() {
        // Given
        let services = createTestServices()
        sut.updateSelectedServices(services)
        
        // When
        let result = sut.selectedServicesText
        
        // Then
        XCTAssertEqual(result, "Haircut, Color")
    }
    
    // MARK: - Validation Tests
    func testValidateName_ShouldDelegateToDefaultViewModel() {
        // Given
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateName("Test Name")
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDefaultViewModel.lastValidatedName, "Test Name")
    }
    
    func testValidateAllFields_WithAllFieldsValid_ShouldReturnTrue() {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testValidateAllFields_WithEmptyClientName_ShouldReturnFalse() {
        // Given
        setupValidAppointmentData()
        
        // When
        let result = sut.validateAllFields(clientName: "")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithInvalidClientName_ShouldReturnFalse() {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateNameResult = false
        
        // When
        let result = sut.validateAllFields(clientName: "Invalid Name")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithNoEmployee_ShouldReturnFalse() {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        sut.updateSelectedServices(createTestServices())
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithNoServices_ShouldReturnFalse() {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithNoStartDate_ShouldReturnFalse() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        sut.updateSelectedServices(createTestServices())
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithNoEndDate_ShouldReturnFalse() {
        // Given
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        sut.updateSelectedServices(createTestServices())
        sut.updateStartTime(Date())
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithEndDateBeforeStartDate_ShouldReturnFalse() {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(-3600) // 1 hour before
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        sut.updateSelectedServices(createTestServices())
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        mockDefaultViewModel.validateNameResult = true
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testValidateAllFields_WithInvalidTimeRange_ShouldReturnFalse() {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = false
        
        // When
        let result = sut.validateAllFields(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Creation & Update Tests
    func testCreateAppointment_WithValidData_ShouldReturnTrue() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = true
        let employeeEntity = MockEmployeeEntity()
        mockDefaultViewModel.employeeEntityToReturn = employeeEntity
        mockDefaultViewModel.serviceEntitiesToReturn = [MockServiceEntity(), MockServiceEntity()]
        
        // When
        let result = await sut.createAppointment(clientName: "Test Client")
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDefaultViewModel.createAppointmentCallCount, 1)
        XCTAssertEqual(mockDefaultViewModel.lastClientName, "Test Client")
        XCTAssertEqual(mockDefaultViewModel.lastEmployee as? MockEmployeeEntity, employeeEntity)
    }
    
    func testCreateAppointment_WithInvalidData_ShouldReturnFalse() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = false
        
        // When
        let result = await sut.createAppointment(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockDefaultViewModel.createAppointmentCallCount, 0)
    }
    
    func testCreateAppointment_WhenEmployeeNotFound_ShouldReturnFalseAndNotifyDelegate() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = true
        mockDefaultViewModel.employeeEntityToReturn = nil
        
        // When
        let result = await sut.createAppointment(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockDefaultViewModel.createAppointmentCallCount, 0)
        XCTAssertTrue(mockDelegate.didFailWithErrorCalled)
        XCTAssertEqual((mockDelegate.lastError as NSError?)?.domain, "AppointmentError")
    }
    
    func testCreateAppointment_WhenServicesFetchFails_ShouldReturnFalseAndNotifyDelegate() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = true
        mockDefaultViewModel.employeeEntityToReturn = MockEmployeeEntity()
        mockDefaultViewModel.shouldThrowOnFetchServices = true
        
        // When
        let result = await sut.createAppointment(clientName: "Test Client")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockDefaultViewModel.createAppointmentCallCount, 0)
        XCTAssertTrue(mockDelegate.didFailWithErrorCalled)
    }
    
    func testUpdateAppointment_WithValidData_ShouldReturnTrue() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = true
        let employeeEntity = MockEmployeeEntity()
        mockDefaultViewModel.employeeEntityToReturn = employeeEntity
        mockDefaultViewModel.serviceEntitiesToReturn = [MockServiceEntity(), MockServiceEntity()]
        let appointment = createTestAppointment()
        
        // When
        let result = await sut.updateAppointment(existingAppointment: appointment, clientName: "Updated Client")
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDefaultViewModel.updateAppointmentCallCount, 1)
        XCTAssertEqual(mockDefaultViewModel.lastClientName, "Updated Client")
        XCTAssertEqual(mockDefaultViewModel.lastEmployee as? MockEmployeeEntity, employeeEntity)
    }
    
    func testUpdateAppointment_WithInvalidData_ShouldReturnFalse() async {
        // Given
        setupValidAppointmentData()
        mockDefaultViewModel.validateAppointmentInputResult = false
        let appointment = createTestAppointment()
        
        // When
        let result = await sut.updateAppointment(existingAppointment: appointment, clientName: "Updated Client")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockDefaultViewModel.updateAppointmentCallCount, 0)
    }
    
    // MARK: - Helper Methods
    private func setupValidAppointmentData() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        let testEmployees = createTestEmployees()
        mockDefaultViewModel.employees = testEmployees
        sut.selectEmployee(at: 0)
        sut.updateStartTime(startDate)
        sut.updateEndTime(endDate)
        sut.updateSelectedServices(createTestServices())
        mockDefaultViewModel.validateNameResult = true
    }
    
    private func createTestEmployees() -> [EmployeeModel] {
        return [
            EmployeeModel(id: "all", name: "All"),
            EmployeeModel(id: "employee1", name: "John Doe"),
            EmployeeModel(id: "employee2", name: "Jane Smith")
        ]
    }
    
    private func createTestServices() -> [ServiceModel] {
        return [
            ServiceModel(id: "service1", title: "Haircut", duration: 30, price: 50),
            ServiceModel(id: "service2", title: "Color", duration: 60, price: 100)
        ]
    }
    
    private func createTestAppointment() -> AppointmentModel {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600)
        let employee = EmployeeModel(id: "employee1", name: "John Doe")
        let service = ServiceModel(id: "service1", title: "Haircut", duration: 30, price: 50)
        
        return AppointmentModel(
            id: "appointment1",
            clientName: "Test Client",
            startTime: startTime,
            endTime: endTime,
            employee: employee,
            services: [service]
        )
    }
    
    private func createTestDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Mock Objects
final class MockDefaultViewModel: DefaultViewModel {
    var delegate: ViewModelDelegate?
    var employees: [EmployeeModel] = []
    var appointments: [AppointmentModel] = []
    var selectedDate: Date = Date()
    var selectedEmployeeId: String?
    
    var validateNameResult = false
    var validateAppointmentInputResult = false
    var validateAppointmentInputCallCount = 0
    var lastValidatedName: String?
    var lastValidatedStartTime: Date?
    var lastValidatedEndTime: Date?
    var servicesForSelectedEmployee: [ServiceModel] = []
    var employeeEntityToReturn: Any?
    var serviceEntitiesToReturn: [Any] = []
    var shouldThrowOnFetchServices = false
    var createAppointmentCallCount = 0
    var updateAppointmentCallCount = 0
    var lastClientName: String?
    var lastStartTime: Date?
    var lastEndTime: Date?
    var lastEmployee: Any?
    var lastServices: [Any] = []
    
    func loadEmployees() async {}
    
    func loadAppointments() async {}
    
    func fetchAppointmentById(by id: String) async throws -> AppointmentEntity? {
        return nil
    }
    
    func deleteAppointment(_ appointment: AppointmentEntity) async {}
    
    func ValidateName(_ name: String) -> Bool {
        lastValidatedName = name
        return validateNameResult
    }
    
    func validateAppointmentInput(startTime: Date, endTime: Date) -> Bool {
        validateAppointmentInputCallCount += 1
        lastValidatedStartTime = startTime
        lastValidatedEndTime = endTime
        return validateAppointmentInputResult
    }
    
    func getServicesForSelectedEmployee() async -> [ServiceModel] {
        return servicesForSelectedEmployee
    }
    
    func fetchEmployeeEntity(by id: String) async -> Any? {
        return employeeEntityToReturn
    }
    
    func fetchServiceEntities(by ids: [String]) async throws -> [Any] {
        if shouldThrowOnFetchServices {
            throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return serviceEntitiesToReturn
    }
    
    func createAppointment(clientName: String, startTime: Date, endTime: Date, employee: Any, services: [Any]) async {
        createAppointmentCallCount += 1
        lastClientName = clientName
        lastStartTime = startTime
        lastEndTime = endTime
        lastEmployee = employee
        lastServices = services
    }
    
    func updateAppointmentModel(appointment: AppointmentModel, clientName: String, startTime: Date, endTime: Date, employee: Any, services: [Any]) async {
        updateAppointmentCallCount += 1
        lastClientName = clientName
        lastStartTime = startTime
        lastEndTime = endTime
        lastEmployee = employee
        lastServices = services
    }
}

final class MockViewModelDelegate: ViewModelDelegate {
    var didFailWithErrorCalled = false
    var lastError: Error?
    
    func didFailWithError(_ error: Error) {
        didFailWithErrorCalled = true
        lastError = error
    }
}

final class MockEmployeeEntity {}
final class MockServiceEntity {}
final class AppointmentEntity {}

// MARK: - Mock Models
struct EmployeeModel: Equatable {
    var id: String
    var name: String
}

struct ServiceModel: Equatable {
    var id: String
    var title: String
    var duration: Int
    var price: Double
}

struct AppointmentModel {
    var id: String
    var clientName: String
    var startTime: Date
    var endTime: Date
    var employee: EmployeeModel
    var services: [ServiceModel]
}
