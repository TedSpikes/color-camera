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
    private let permanentNavItem = UINavigationItem(title: "Pick a filter")
    
    var filterManager: FilterManager
    var delegate: IFilterPickerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBAction func closeModal(_ sender: UIBarButtonItem) {
        delegate?.dismissPicker(completion: nil)
    }
    
    @IBAction func switchCompactMode(_ sender: UIBarButtonItem) {
        delegate?.switchedCompactMode()
    }
    
    required init?(coder: NSCoder) {
        filterManager = FilterManager()
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        filterManager = FilterManager()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib.init(nibName: "FilterPickerCellView", bundle: nil), forCellReuseIdentifier: "filterPickerCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        let closeButton = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(FilterPickerViewController.closeModal(_:)))
        permanentNavItem.setRightBarButton(closeButton, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let inCompact = delegate?.shouldUseCompactPicker {
            let image  = inCompact ? UIImage(systemName: "rectangle.expand.vertical") : UIImage(systemName: "rectangle.compress.vertical")
            let switchCompactModeButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(FilterPickerViewController.switchCompactMode(_:)))
            permanentNavItem.setLeftBarButton(switchCompactModeButton, animated: false)
            navBar.setItems([permanentNavItem], animated: true)
            
            let tableViewCornerRadius: CGFloat = inCompact ? 12 : 0
            tableView.layer.cornerRadius       = tableViewCornerRadius
            tableView.layer.maskedCorners      = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            tableView.layer.masksToBounds      = true
        }
    }
}

// MARK: UITableViewDelegate
extension FilterPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let activeCell = tableView.cellForRow(at: indexPath) as? FilterPickerCell
        else { os_log(.error, "Couldn't get cell at %s as FilterPickerCell", indexPath.description)
               return }
        guard
            let filterName = activeCell.nameLabel?.text
        else { os_log(.error, "Selected cell %s does not have a title", activeCell.description)
               return }
        
        delegate?.picked(filterName: filterName)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: UITableViewDataSource
extension FilterPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterManager.getFilterNames().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterPickerCell") as! FilterPickerCell
        let filterName: String = filterManager.getFilterNames()[indexPath.row]
        let colorMatrix: ColorMatrix = filterManager.getColorMatrix(name: filterName)!
        
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
        let filter = filterManager.filter(withName: filterName) as! VisionFilter
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

protocol IFilterPickerDelegate {
    var shouldUseCompactPicker: Bool { get set }
    
    func picked(filterName: String) -> Void
    
    func switchedCompactMode() -> Void
    
    func dismissPicker(completion: (() -> Void)?) -> Void
}
