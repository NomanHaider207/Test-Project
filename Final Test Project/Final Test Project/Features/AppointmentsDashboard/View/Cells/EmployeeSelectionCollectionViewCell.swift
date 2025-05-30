//
//  EmployeeSelectionCollectionViewCell.swift
//  Final Test Project
//
//  Created by Dev  on 5/7/25.
//

import UIKit

class EmployeeSelectionCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "employeeSelectionCell"
    @IBOutlet weak var employeeNameLabel: UILabel!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
    }

    func configure(with employee: Employees, isSelected: Bool) {
        employeeNameLabel.text = employee.name
        
        if isSelected {
            contentView.backgroundColor = UIColor(named: "appColor")
            employeeNameLabel.textColor = .white
        } else {
            contentView.backgroundColor = .clear
            employeeNameLabel.textColor = .black
        }
    }
}

