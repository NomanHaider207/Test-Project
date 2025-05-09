//
//  ViewController.swift
//  Final Test Project
//
//  Created by Dev  on 5/7/25.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    
    // MARK: - Oulets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    private var viewModel: DefaultViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "AppointmentCardTableViewCell", bundle: nil), forCellReuseIdentifier: "appointmentCard")
        
        self.viewModel = AppEnvironment.shared.viewModel
        
        Task {
            await viewModel.loadEmployees()
            await viewModel.loadAppointments()
            
            self.collectionView.reloadData()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await viewModel.loadAppointments()
        }
    }
    
    @IBAction func onDateChange(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
        tableView.reloadData()
    }
    
}


// MARK: - CollectionView Datasource and Delegate
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.employees.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "employeeSelectionCell", for: indexPath) as! EmployeeSelectionCollectionViewCell
        cell.employeeNameLabel.text =  viewModel.employees[indexPath.row].name
        cell.layer.cornerRadius = 15
        cell.layer.masksToBounds = true
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedEmployee = viewModel.employees[indexPath.row]
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
            selectedCell.contentView.backgroundColor = UIColor(named: "appColor")
        }
        if selectedEmployee.name == "All" {
            viewModel.selectedEmployeeId = nil
        } else {
            viewModel.selectedEmployeeId = selectedEmployee.id
        }
        tableView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let deselectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
            deselectedCell.contentView.backgroundColor = UIColor.clear
        }
    }


}


// MARK: - TableView Datasource and Delegate
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
     
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return 12
     }

     func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
         let spacer = UIView()
         spacer.backgroundColor = .clear
         return spacer
     }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         guard let cell = tableView.dequeueReusableCell(withIdentifier: "appointmentCard", for: indexPath) as? AppointmentCardTableViewCell else {
             return UITableViewCell()
         }

        
         let appointment = viewModel.appointments[indexPath.section]
                  
         cell.employeeNameLabelTableViewCell.text = appointment.employee.name
         cell.clientNameTableViewCell.text = appointment.clientName
         
         let serviceTitles = appointment.services.map { $0.title }
         cell.serviceLabelTableViewCell.text = serviceTitles.joined(separator: ", ")
         
         let dateFormatter = DateFormatter()
         dateFormatter.dateStyle = .medium
         dateFormatter.timeStyle = .short
         let formattedStartTime = dateFormatter.string(from: appointment.startTime)
         cell.timeLabelTableViewCell.text = formattedStartTime
         
         cell.delegate = self
         return cell
     }

    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.datePicker.isHidden = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            if datePicker.isHidden {
                datePicker.isHidden = false
                datePicker.alpha = 0
                
                UIView.animate(withDuration: 0.3) {
                    self.datePicker.alpha = 1
                }
            }
        }
    }
}

// MARK: - AppointmentCardCellDelegate
extension ViewController: AppointmentCardCellDelegate {

    func didTapEdit(on cell: AppointmentCardTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let appointment = viewModel.appointments[indexPath.section]
        // Implement edit logic if needed
        print("Edit tapped for appointment: \(appointment.clientName)")
    }

    func didTapDelete(on cell: AppointmentCardTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let appointment = viewModel.appointments[indexPath.section]

        let alert = UIAlertController(title: "Confirm Deletion",
                                      message: "Are you sure you want to delete this appointment?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            Task {
                    let appointmentEntity = try await self.viewModel.fetchAppointmentById(by: appointment.id)
                    await self.viewModel.deleteAppointment(appointmentEntity!)
                    self.tableView.reloadData()
            }
        }))
        present(alert, animated: true)
    }
}

