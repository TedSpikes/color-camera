//
//  FilterPickerViewController.swift
//  Color Camera
//
//  Created by Fedor on 6/9/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import UIKit

class FilterPickerViewController: UIViewController {
    let filters:[(String, String)] = [
        ( "Normal", "As the camera sees it." ),
        ( "Protanopia", "Full red-blindness, missing L-cones." ),
        ( "Protanomaly", "Red-blindness, defective L-cones." ),
        ( "Deuteranopia", "Full green-blindness." ),
        ( "Deuteranomaly", "Varies per person, green sensitivity is moved to red." ),
        ( "Tritanopia", "Rare form of missing S-cones, blue can be confused with green and yellow with violet." ),
        ( "Tritanomaly", "Usually, a lighter form of Tritanopia." ),
        ( "Achromatopsia", "Total color blindness." ),
        ( "Achromatomaly", "An alleviated form of Achromatopsia" )
    ]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBAction func closeModal(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib.init(nibName: "FilterPickerCellView", bundle: nil), forCellReuseIdentifier: "filterPickerCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
}

extension FilterPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filterName = self.tableView.cellForRow(at: indexPath)?.textLabel?.text
        let presenter = self.presentingViewController as! ViewportViewController
        do {
            try presenter.changeFilterType(to: filterName!)
        } catch {
            print(error)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension FilterPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterPickerCell") as! FilterPickerCell
        let filterDescription = self.filters[indexPath.row]
        cell.nameLabel?.text = filterDescription.0
        cell.descriptionLabel?.text = filterDescription.1
        
        return cell
    }
}
