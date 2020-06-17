//
//  FilterPickerViewController.swift
//  Color Camera
//
//  Created by Ted on 6/9/19.
//  Copyright © 2019 Ted Kostylev. All rights reserved.
//

import UIKit
import os.log

class FilterPickerViewController: UIViewController {
    var filterManager: FilterManager
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBAction func closeModal(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        self.filterManager = FilterManager()
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.filterManager = FilterManager()
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
        guard
            let activeCell = self.tableView.cellForRow(at: indexPath) as? FilterPickerCell
        else {
            os_log(.error, "Couldn't get cell at %s as FilterPickerCell", indexPath.description)
            return
        }
        guard
            let filterName = activeCell.nameLabel?.text
        else {
            os_log(.error, "Selected cell %s does not have a title", activeCell.description)
            return
        }
        let presenter  = self.presentingViewController as! ViewportViewController
        presenter.switchToFilter(name: filterName)
        do {
            try setUserDefault(value: filterName, forKey: .activeFilter)
        } catch {
            os_log(.error, "Unexpected error when trying to save the active filter: %s", error.localizedDescription)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UITableViewDataSource
extension FilterPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterManager.getFilterNames().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterPickerCell") as! FilterPickerCell
        let filterName: String = self.filterManager.getFilterNames()[indexPath.row]
        let colorMatrix: ColorMatrix = self.filterManager.getColorMatrix(name: filterName)!
        
        cell.nameLabel?.text = colorMatrix.name
        cell.descriptionLabel?.text = colorMatrix.description
        cell.exampleImageView.image = getFilteredImage(fromUIImage: UIImage(named: "Pencils")!, for: colorMatrix.name)
        return cell
    }
}

// MARK: Filter logic
// Similar to the viewport
extension FilterPickerViewController {
    func getFilteredImage(fromUIImage inputImage: UIImage, for filterName: String, oriented orientation: CGImagePropertyOrientation = .up) -> UIImage? {
        let filter = self.filterManager.filter(withName: filterName) as! VisionFilter
        var image: CIImage = CIImage()
        
        if inputImage.cgImage != nil {
            image = CIImage(cgImage: inputImage.cgImage!)
        } else if inputImage.ciImage != nil {
            image = inputImage.ciImage!
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        var result = filter.value(forKey: kCIOutputImageKey) as! CIImage
        result = result.oriented(orientation)
        return UIImage(ciImage: result)
    }
}
