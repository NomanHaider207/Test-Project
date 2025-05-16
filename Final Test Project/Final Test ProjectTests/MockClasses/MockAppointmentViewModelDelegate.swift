//
//  MockAppointmentViewModelDelegate.swift
//  Final Test Project
//
//  Created by Dev  on 5/15/25.
//

import Foundation
@testable import Final_Test_Project

class MockAppointmentViewModelDelegate: ViewModelDelegate {
    var didUpdateDataCalled = false
    var didFailWithErrorCalled = false
    
    func didFailWithError(_ error: any Error) {
        didFailWithErrorCalled =  true
    }
    
    func didUpdateData() {
        didUpdateDataCalled = true
    }
}
