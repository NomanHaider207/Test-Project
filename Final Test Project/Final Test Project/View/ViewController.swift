//
//  ViewController.swift
//  Final Test Project
//
//  Created by Dev on 5/7/25.
//

import UIKit
import CoreData

// MARK: - ViewController

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    private var viewModel: DefaultViewModel!
    private var screenMode: SelectionType = .addAppointment
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        tableView.register(UINib(nibName: "AppointmentCardTableViewCell", bundle: nil), forCellReuseIdentifier: "appointmentCard")
        viewModel = AppEnvironment.shared.viewModel
        viewModel.delegate = self
    }
    
    private func loadData() {
        Task {
            await viewModel.loadEmployees()
            await viewModel.loadAppointments()
            collectionView.reloadData()
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func onDateChange(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
        tableView.reloadData()
    }
    
    @IBAction func addAppointmentPressed(_ sender: UIButton) {
        screenMode = .addAppointment
        performSegue(withIdentifier: "addAppointmentSegue", sender: self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addVC = segue.destination as? AddAppointmentViewController {
            addVC.delegate = self
            
            switch screenMode {
            case .addAppointment:
                addVC.selectionType = .addAppointment
            case .editAppointment(let appointment):
                addVC.selectionType = .editAppointment(existingAppointment: appointment)
            }
        }
    }
}

// MARK: - AddAppointmentDelegate
extension ViewController: AddAppointmentDelegate {
    func didAddAppointment() {
        Task {
            await viewModel.loadAppointments()
            tableView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.employees.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "employeeSelectionCell", for: indexPath) as! EmployeeSelectionCollectionViewCell
        let employee = viewModel.employees[indexPath.row]
        
        cell.employeeNameLabel.text = employee.name
        cell.layer.cornerRadius = 15
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedEmployee = viewModel.employees[indexPath.row]
        
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
            selectedCell.contentView.backgroundColor = UIColor(named: "appColor")
        }
        
        viewModel.selectedEmployeeId = selectedEmployee.name == "All" ? nil : selectedEmployee.id
        tableView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let deselectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
            deselectedCell.contentView.backgroundColor = UIColor.clear
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        cell.serviceLabelTableViewCell.text = appointment.services.map { $0.title }.joined(separator: ", ")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        
        let timeText = "\(formatter.string(from: appointment.startTime)) - \(formatter.string(from: appointment.endTime))"
        cell.timeLabelTableViewCell.text = timeText
        
        cell.delegate = self
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        datePicker.isHidden = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0, datePicker.isHidden {
            datePicker.alpha = 0
            datePicker.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.datePicker.alpha = 1
            }
        }
    }
}

// MARK: - AppointmentCardCellDelegate
extension ViewController: AppointmentCardCellDelegate {
    
    func didTapEdit(on cell: AppointmentCardTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let appointment = viewModel.appointments[indexPath.section]
        screenMode = .editAppointment(existingAppointment: appointment)
        performSegue(withIdentifier: "addAppointmentSegue", sender: self)
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

// MARK: - ViewModelDelegate
extension ViewController: ViewModelDelegate {
    
    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.showErrorAlert(message: error.localizedDescription)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
