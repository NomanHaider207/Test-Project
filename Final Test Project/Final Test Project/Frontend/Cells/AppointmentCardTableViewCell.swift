//
//  AppointmentCardTableViewCell.swift
//  Final Test Project
//
//  Created by Dev  on 5/7/25.
//

import UIKit

// MARK: - AppointmentCardCellDelegate
protocol AppointmentCardCellDelegate: AnyObject {
    func didTapEdit(on cell: AppointmentCardTableViewCell)
    func didTapDelete(on cell: AppointmentCardTableViewCell)
}

class AppointmentCardTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var employeeNameLabelTableViewCell: UILabel!
    @IBOutlet weak var clientNameTableViewCell: UILabel!
    @IBOutlet weak var timeLabelTableViewCell: UILabel!
    @IBOutlet weak var serviceLabelTableViewCell: UILabel!
    @IBOutlet weak var optionsButton: UIButton!
    
    static let identifier = "appointmentCard"
    
    weak var delegate: AppointmentCardCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4

        setupMenu()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupMenu() {
        let menuItems: [UIAction] = [
            UIAction(title: "Edit", image: UIImage(systemName: "pencil"), handler: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didTapEdit(on: self)
            }),
            UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didTapDelete(on: self)
            })
        ]

        let menu = UIMenu(title: "Options", children: menuItems)
        optionsButton.menu = menu
        optionsButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func onOptionsButtonPressed(_ sender: UIButton) {
    }
    
    func configure(_ cell: AppointmentCardTableViewCell, at section: Int, appointment: AppointmentModel, viewModel: DefaultViewModel) {
        
        cell.employeeNameLabelTableViewCell.text = appointment.employee.name
        cell.clientNameTableViewCell.text = appointment.clientName
        cell.serviceLabelTableViewCell.text = viewModel.formatServicesList(appointment.services)
        cell.timeLabelTableViewCell.text = viewModel.formattedTime(for: appointment)
    }
    
}
