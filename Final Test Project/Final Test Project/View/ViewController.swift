// ViewController.swift - Updated to use ViewModel for business logic

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
        viewModel = DefaultViewModel(networkManager: AppEnvironment.shared.networkManger)
        viewModel.delegate = self
    }
    
    private func loadData() {
        Task {
            await viewModel.loadEmployees()
            await viewModel.loadAppointments()
            
            tableView.reloadData()
            collectionView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func onDateChange(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
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
    
    private func showAlert(title: String,message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            configureCell(cell, with: employee)
            return cell
        }

        // MARK: - UICollectionViewDelegate

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            viewModel.selectEmployee(at: indexPath.row)
            collectionView.reloadData() // Reload all cells to update selected background
        }

        // Optional: you may remove this since reloadData will handle deselection UI
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            if let deselectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
                deselectedCell.contentView.backgroundColor = .clear
            }
        }

        // MARK: - Cell Configuration

        private func configureCell(_ cell: EmployeeSelectionCollectionViewCell, with employee: EmployeeModel) {
            cell.employeeNameLabel.text = employee.name
            cell.layer.cornerRadius = 15
            cell.layer.masksToBounds = true

            if let selectedId = viewModel.selectedEmployeeId, employee.id == selectedId {
                cell.contentView.backgroundColor = UIColor(named: "appColor")
            } else if employee.name == "All" && viewModel.selectedEmployeeId == nil {
                cell.contentView.backgroundColor = UIColor(named: "appColor")
            } else {
                cell.contentView.backgroundColor = .clear
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
        
        configure(cell, at: indexPath.section)
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        datePicker.isHidden = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0, datePicker.isHidden {
            datePicker.isHidden = false
        }
    }
    
    private func configure(_ cell: AppointmentCardTableViewCell, at section: Int) {
        let appointment = self.viewModel.appointments[section]

        cell.employeeNameLabelTableViewCell.text = appointment.employee.name
        cell.clientNameTableViewCell.text = appointment.clientName
        cell.serviceLabelTableViewCell.text = appointment.services.map { $0.title }.joined(separator: ", ")
        cell.timeLabelTableViewCell.text = viewModel.formattedTime(for: appointment)

        cell.delegate = self
    }
}

// MARK: - AppointmentCardCellDelegate
extension ViewController: AppointmentCardCellDelegate {
    
    func didTapEdit(on cell: AppointmentCardTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let appointment = viewModel.appointments[indexPath.section]
        screenMode = .editAppointment(existingAppointment: appointment)
        performSegue(withIdentifier: "addAppointmentSegue", sender: self)
    }

    func didTapDelete(on cell: AppointmentCardTableViewCell) {
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            let appointment = viewModel.appointments[indexPath.section]
            
            // Create the alert
            let alert = UIAlertController(
                title: "Confirm Deletion",
                message: "Are you sure you want to delete this appointment?",
                preferredStyle: .alert
            )

            // Cancel button
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            // Delete button
            alert.addAction(UIAlertAction(
                title: "Delete",
                style: .destructive,
                handler: { _ in
    
                    Task {
                        await self.viewModel.deleteAppointment(appointment.id)
                    }
                }
            ))
            present(alert, animated: true)
        }
}

// MARK: - ViewModelDelegate
extension ViewController: ViewModelDelegate {
    
    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    func didUpdateData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.collectionView.reloadData()
        }
    }
}
