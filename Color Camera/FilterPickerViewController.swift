//
//  FilterPickerViewController.swift
//  Color Camera
//
//  Created by Fedor on 6/9/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import UIKit

class FilterPickerViewController: UIViewController {
    let filters:[String] = [
        "Normal",
        "Protanopia",
        "Protanomaly",
        "Deuteranopia",
        "Deuteranomaly",
        "Tritanopia",
        "Tritanomaly",
        "Achromatopsia",
        "Achromatomaly"
    ]
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func closeModal(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "FilterPickerCell")
        cell.textLabel?.text = self.filters[indexPath.row]
        cell.detailTextLabel?.text = "Detail"
        
        return cell
    }
}
