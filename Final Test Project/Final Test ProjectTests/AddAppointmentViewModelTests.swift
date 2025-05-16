import XCTest
@testable import Final_Test_Project

@MainActor
final class AddAppointmentViewModelTests: XCTestCase {
    
    var viewModel: AddAppointmentViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AddAppointmentViewModel(networkManager: MockNetworkManager())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Test Cases of function selectEmployee(at: index) to check all condition
    func testSelectEmployeeUpdatesSelectedEmployeeAndId() {
        let employee = EmployeeModel(id: UUID(), name: "Noman", services: [])
        viewModel.employees = [employee]

        viewModel.selectEmployee(at: 0)

        XCTAssertEqual(viewModel.selectedEmployee?.id, employee.id)
        XCTAssertEqual(viewModel.selectedEmployeeId, employee.id)
        XCTAssertTrue(viewModel.selectedServices.isEmpty)
    }
    
    
    func testResetSelectedEmployeeClearsSelection() {
        viewModel.selectedEmployee = EmployeeModel(id: UUID(), name: "Noman Haider", services: [])
        viewModel.selectedEmployeeId = UUID()

        viewModel.resetSelectedEmployee()

        XCTAssertNil(viewModel.selectedEmployee)
        XCTAssertNil(viewModel.selectedEmployeeId)
    }
    
    // MARK: - Test Cases of function updateStartTime(date) to check all condition
    func testUpdateStartTime(){
        let date = Date()
        
        viewModel.updateStartTime(date)
        
        XCTAssertEqual(viewModel.startDate, date)
        XCTAssertNil(viewModel.endDate)
    }
    
    func testUpdateEndTime(){
        let date = Date()
        
        viewModel.updateEndTime(date)
        
        XCTAssertEqual(viewModel.endDate, date)
    }
    
    // MARK: - Test Cases of function canSetEndTime() to check all condition
    func testCanSetEndTimeOnlyIfAfterStart() {
        let start = Date()
        let validEnd = start.addingTimeInterval(3600)
        let invalidEnd = start.addingTimeInterval(-3600)

        viewModel.updateStartTime(start)

        XCTAssertTrue(viewModel.canSetEndTime(validEnd))
        XCTAssertFalse(viewModel.canSetEndTime(invalidEnd))
    }
    
    func testValidateTimeRange(){
        let start = Date()
        let validTimeRange = start.addingTimeInterval(4*60*60)
        let invalidTimeRange = start.addingTimeInterval(6*60*60)

        viewModel.updateStartTime(start)
        viewModel.updateEndTime(validTimeRange)

        XCTAssertTrue(viewModel.validateTimeRange())
        
        viewModel.updateEndTime(invalidTimeRange)
        XCTAssertFalse(viewModel.validateTimeRange())
    }
    
    // MARK: - Test Cases of function validateUserName() to check all condition
    func testValidateUserName(){
        let validName: String = "Noman Haider"
        let invalidName: String = "Noman 123"
        
        XCTAssertTrue(viewModel.validateName(validName))
        XCTAssertFalse(viewModel.validateName(invalidName))
    }
    
    // MARK: - Test Cases of function selectSetvices() to check all condition
    func testCanSelectServcies() {
        viewModel.selectedEmployee = EmployeeModel(id: UUID(), name: "Noman", services: [])
        XCTAssertTrue(viewModel.canSelectServices())
        
        viewModel.selectedEmployee = nil
        XCTAssertFalse(viewModel.canSelectServices())
    }
    
    func testUpdateSelectedServices() {
        let services = [
            ServiceModel(id: UUID(), title: "Haircut"),
            ServiceModel(id: UUID(), title: "Massage")
        ]

        viewModel.updateSelectedServices(services)
        XCTAssertEqual(viewModel.selectedServices.count, 2)
        XCTAssertEqual(viewModel.selectedServices.first?.title, "Haircut")
    }
    
    // MARK: - Test Cases of function populateDataInFieldsForEditing to check all condition
    func testPopulateDataForEditing(){
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(2*60*60)
        let employee = EmployeeModel(id: UUID(), name: "Noman", services: [])
        let services = [
            ServiceModel(id: UUID(), title: "Haircut"),
            ServiceModel(id: UUID(), title: "Massage")
        ]
        
        
        let appointment = AppointmentModel(id: UUID(), clientName: "Ibrahim", startTime: startDate, endTime: endDate, employee: employee, services: services)
        
        viewModel.populateDataForEditing(with: appointment)
        
        XCTAssertEqual(viewModel.clientName, "Ibrahim")
        XCTAssertEqual(viewModel.selectedServices.count, 2)
    }
    
    // MARK: - Test Cases of function updateStartTime to check all condition
    func testFormattedStartTimeReturnsCorrectString() {
        let date = Date(timeIntervalSince1970: 1_694_000_000) 
        viewModel.updateStartTime(date)

        let formatted = viewModel.formattedStartTime
        XCTAssertFalse(formatted.isEmpty)
    }

    func testFormattedEndTimeReturnsCorrectString() {
        let date = Date(timeIntervalSince1970: 1_694_000_000)
        viewModel.updateEndTime(date)

        let formatted = viewModel.formattedEndTime
        XCTAssertFalse(formatted.isEmpty)
    }
    
    
    // MARK: - Test Cases of function createAppointment method to check all condition using mock repos
    func testAddAppointmentSuccess() async {
        
        let employeeId = UUID()
        let serviceId = UUID()
        let mockManager = MockNetworkManager()

        let viewModel = AddAppointmentViewModel(networkManager: mockManager)

        let employee = EmployeeModel(id: employeeId, name: "John", services: [])
        let service = ServiceModel(id: serviceId, title: "Haircut")
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!

        viewModel.clientName = "Noman"
        viewModel.selectedEmployee = employee
        viewModel.selectedServices = [service]
        viewModel.startDate = startTime
        viewModel.endDate = endTime

        Task{
            let result = await viewModel.createAppointment(clientName: "Noman")
            XCTAssertTrue(result)
        }

    }
   
    func testAddAppointmentFail() async {
        
        let employeeId = UUID()
        let serviceId = UUID()
        let mockManager = MockNetworkManager(shouldFail: true)

        let viewModel = AddAppointmentViewModel(networkManager: mockManager)

        let employee = EmployeeModel(id: employeeId, name: "John", services: [])
        let service = ServiceModel(id: serviceId, title: "Haircut")
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!

        viewModel.clientName = "Noman"
        viewModel.selectedEmployee = employee
        viewModel.selectedServices = [service]
        viewModel.startDate = startTime
        viewModel.endDate = endTime

        Task{
            let result = await viewModel.createAppointment(clientName: "Noman")
            XCTAssertFalse(result)
        }
    }
    
    func testAddAppointmentHaveConflict() async {
        
        let employeeId = UUID()
        let serviceId = UUID()
        let mockManager = MockNetworkManager(shouldConflict: true)

        let viewModel = AddAppointmentViewModel(networkManager: mockManager)

        let employee = EmployeeModel(id: employeeId, name: "John", services: [])
        let service = ServiceModel(id: serviceId, title: "Haircut")
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!

        viewModel.clientName = "Noman"
        viewModel.selectedEmployee = employee
        viewModel.selectedServices = [service]
        viewModel.startDate = startTime
        viewModel.endDate = endTime

        Task{
            let result = await viewModel.createAppointment(clientName: "Noman")
            XCTAssertFalse(result)
        }
    }

    
}

