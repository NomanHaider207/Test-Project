//
//  AddEmployeeAndServiceViewController.swift
//  Final Test Project
//
//  Created by Dev  on 5/13/25.
//

import UIKit


enum AddType{
    case employee, service
}

class AddEmployeeAndServiceViewController: UIViewController {

    
    
    @IBOutlet weak var entitiyNameLabel: UILabel!
    @IBOutlet weak var entittyNameTextView: UITextField!
    @IBOutlet weak var servicesLabel: UILabel!
    @IBOutlet weak var addServicesForEmployeeTextView: UITextField!
    
    // MARK: - Properties
    var addType: AddType = .employee
    private var selectedServices: [ServiceModel] = []
    private var availableServicesForEmployee: [ServiceModel] = []

    private var viewModel: DefaultViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = AppEnvironment.shared.viewModel
        switch addType {
        case .employee:
            addServicesForEmployeeTextView.inputView = UIView()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(serviceFieldTapped))
            addServicesForEmployeeTextView.addGestureRecognizer(tapGesture)
        case .service:
            entitiyNameLabel.text = "Service Name"
            entittyNameTextView.placeholder = "ServiceName"
            
            servicesLabel.isHidden = true
            addServicesForEmployeeTextView.isHidden = true
        }
        
        Task {
            await viewModel.fetchServices()
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showServiceSelection",
           let destinationVC = segue.destination as? ServiceSelectionViewController {
            destinationVC.availableServices = availableServicesForEmployee
            destinationVC.selectedServices = selectedServices
            destinationVC.delegate = self
        }
    }
    
    @objc private func serviceFieldTapped() {
        let employeeName = entitiyNameLabel.text
        guard employeeName != nil else {
            showAlert(message: "Please select an employee first.")
            return
        }
        performSegue(withIdentifier: "showServiceSelection", sender: self)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    

    @IBAction func onBackButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func onSaveButtonPressed(_ sender: UIButton) {
    }
}

extension AddEmployeeAndServiceViewController: ServiceSelectionDelegate {
    func didSelectServices(_ services: [ServiceModel]) {
        self.selectedServices = services
        self.addServicesForEmployeeTextView.text = services.map { $0.title }.joined(separator: ", ")
    }
}
