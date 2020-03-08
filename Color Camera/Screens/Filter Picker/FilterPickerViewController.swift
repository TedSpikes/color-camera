//
//  FilterPickerViewController.swift
//  Color Camera
//
//  Created by Ted on 6/9/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import UIKit

class FilterPickerViewController: UIViewController {
    var manager: FilterManager
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBAction func closeModal(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        self.manager = FilterManager()
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.manager = FilterManager()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib.init(nibName: "FilterPickerCellView", bundle: nil), forCellReuseIdentifier: "filterPickerCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
}

// MARK: UITableViewDelegate
extension FilterPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let activeCell = self.tableView.cellForRow(at: indexPath) as? FilterPickerCell else {
            fatalError()
        }
        guard let filterName: String = activeCell.nameLabel?.text else { fatalError("Time to rewrite this properly") }
        let presenter = self.presentingViewController as! ViewportViewController
        presenter.switchToFilter(name: filterName)
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UITableViewDataSource
extension FilterPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.manager.getFilterNames().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterPickerCell") as! FilterPickerCell
        let filterName: String = self.manager.getFilterNames()[indexPath.row]
        let colorMatrix: ColorMatrix = self.manager.getColorMatrix(name: filterName)!
        
        cell.nameLabel?.text = colorMatrix.name
        cell.descriptionLabel?.text = colorMatrix.description
        return cell
    }
}
