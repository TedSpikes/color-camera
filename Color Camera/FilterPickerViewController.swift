//
//  FilterPickerViewController.swift
//  Color Camera
//
//  Created by Fedor on 6/9/19.
//  Copyright © 2019 Fedor Kostylev. All rights reserved.
//

import UIKit

class FilterPickerViewController: UIViewController {
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

extension FilterPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "FilterPickerCell")
        cell.textLabel?.text = "Test"
        cell.detailTextLabel?.text = "Detail"
        
        return cell
    }
    
    
}
