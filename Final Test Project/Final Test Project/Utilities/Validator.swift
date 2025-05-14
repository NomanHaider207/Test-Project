//
//  Validator.swift
//  Final Test Project
//
//  Created by Dev  on 5/14/25.
//

import Foundation

enum ValidationError: LocalizedError {
    case invalidUserName
    case invalidAppointmentDuration

    var errorDescription: String? {
        switch self {
        case .invalidUserName:
            return "Client name should contain alphabets only."
        case .invalidAppointmentDuration:
            return "Appointment duration must be greater than 0 and not exceed 5 hours."
        }
    }
}

final class Validator {
    
    /// Validates that the username contains only alphabets (A-Z, a-z)
    static func isValidUserName(_ name: String) -> Bool {
        let regex = "^[A-Za-z ]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: name)
    }
    
    /// Validates that the appointment duration does not exceed 2 days
    static func validateAppointmentDuration(startTime: Date, endTime: Date) -> Result<Void, ValidationError> {
            let duration = endTime.timeIntervalSince(startTime)
            let maxDuration: TimeInterval = 5 * 60 * 60 // 2 hours in seconds
        
            guard duration > 0 && duration <= maxDuration else {
                return .failure(.invalidAppointmentDuration)
            }

            return .success(())
        }
}


