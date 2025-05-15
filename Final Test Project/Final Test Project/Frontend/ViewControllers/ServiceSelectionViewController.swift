//
//  SelectServicesViewController.swift
//  Final Test Project
//
//  Created by Dev  on 5/12/25.
//

import UIKit

protocol ServiceSelectionDelegate: AnyObject {
    func didSelectServices(_ services: [ServiceModel])
}


class ServiceSelectionViewController: UIViewController {
    
    @IBOutlet weak var tabelView: UITableView!
    
    var availableServices: [ServiceModel] = []
    var selectedServices: [ServiceModel] = []
    weak var delegate: ServiceSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabelView.delegate = self
        tabelView.dataSource = self
        tabelView.allowsMultipleSelection = true
    }
    
    
    @IBAction func onDoneButtonPressed(_ sender: UIButton) {
        delegate?.didSelectServices(selectedServices)
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func onBackButtonPressed(_ sender: UIButton) {
        delegate?.didSelectServices([])
        self.dismiss(animated: true)
    }
    
}

// MARK: - TableView Delegate and Datasource
extension ServiceSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableServices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = availableServices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath)
        cell.textLabel?.text = service.title
        
        if selectedServices.contains(where: { $0.id == service.id }) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = availableServices[indexPath.row]

        if let index = selectedServices.firstIndex(where: { $0.id == service.id }) {
            selectedServices.remove(at: index)
        } else {
            selectedServices.append(service)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

}
