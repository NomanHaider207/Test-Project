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
    
}
