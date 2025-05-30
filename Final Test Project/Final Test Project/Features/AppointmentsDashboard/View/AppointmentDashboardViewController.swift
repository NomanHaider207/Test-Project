// ViewController.swift - Updated to use ViewModel for business logic

import UIKit
import CoreData

// MARK: - ViewController

class AppoinmentDashboardViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    private var viewModel: AppointmentDashboardViewModel!
    
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        self.setupTableViewCell()
        loadData()
    }
    
    // MARK: - Actions
    @IBAction func onDateChange(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
    }
    
    @IBAction func addAppointmentPressed(_ sender: UIButton) {
        viewModel.screenMode = .add
        performSegue(withIdentifier: "addAppointmentSegue", sender: self)
    }
    
    // MARK: - Setup
    private func setupTableViewCell() {
        tableView.register(UINib(nibName: AppointmentCardTableViewCell.appointmentTableViewCellIdentifier, bundle: nil), forCellReuseIdentifier: AppointmentCardTableViewCell.identifier)
    }
    
    private func setupViewModel() {
        viewModel = AppointmentDashboardViewModel(networkManager: AppEnvironment.shared.networkManger)
        viewModel.delegate = self
    }
    
    private func loadData() {
        Task {
            
            async let employeesTask: () = viewModel.loadEmployees()
            async let appointmentsTask: () = viewModel.loadAppointments()

            await employeesTask
            await appointmentsTask

            tableView.reloadData()
            collectionView.reloadData()
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addVC = segue.destination as? AppointmentFormViewController {
            addVC.delegate = self
            addVC.formMode = viewModel.screenMode
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension AppoinmentDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getEmployeeListLength()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EmployeeSelectionCollectionViewCell.identifier,
            for: indexPath
        ) as? EmployeeSelectionCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let employee = viewModel.employees[indexPath.row]
        let isSelected = viewModel.isEmployeeSelected(employee)
        cell.configure(with: employee, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectEmployee(at: indexPath.row)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let deselectedCell = collectionView.cellForItem(at: indexPath) as? EmployeeSelectionCollectionViewCell {
            deselectedCell.contentView.backgroundColor = .clear
        }
    }
}


// MARK: - UITableViewDataSource & Delegate
extension AppoinmentDashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getAppointmentListLength()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AppointmentCardTableViewCell.identifier, for: indexPath) as? AppointmentCardTableViewCell else {
            return UITableViewCell()
        }
        
        let appointment = viewModel.appointment(at: indexPath.section)
        cell.configure(cell, at: indexPath.section, appointment: appointment, viewModel: viewModel)
        cell.delegate = self
        
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
}

// MARK: - AppointmentCardCellDelegate
extension AppoinmentDashboardViewController: AppointmentCardCellDelegate {
    
    func didTapEdit(on cell: AppointmentCardTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let appointment = viewModel.appointments[indexPath.section]
        viewModel.screenMode = .edit(existingAppointment: appointment)
        performSegue(withIdentifier: "addAppointmentSegue", sender: self)
    }

    func didTapDelete(on cell: AppointmentCardTableViewCell) {
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            let appointment = viewModel.appointments[indexPath.section]
            
            let alert = UIAlertController(
                title: "Confirm Deletion",
                message: "Are you sure you want to delete this appointment?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
            alert.addAction(UIAlertAction(
                title: "Delete",
                style: .destructive,
                handler: { _ in
    
                    Task {
                        await self.viewModel.deleteAppointment(appointment.id!)
                    }
                }
            ))
            present(alert, animated: true)
        }
}

// MARK: - AddAppointmentDelegate
extension AppoinmentDashboardViewController: AddAppointmentDelegate {
    func didAddAppointment() {
        Task {
            await viewModel.loadAppointments()
            tableView.reloadData()
        }
    }
}

// MARK: - ViewModelDelegate
extension AppoinmentDashboardViewController: ViewModelDelegate {
    
    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            AlertManager.shared.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    func didUpdateData() {
            self.tableView.reloadData()
    }
}
