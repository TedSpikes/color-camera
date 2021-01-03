//
//  Toastview.swift
//  Color Camera
//
//  Created by Ted Kostylev on 6/8/20.
//  Copyright © 2020 Ted Kostylev. All rights reserved.
//

import UIKit
import os.log

class Toast {
    static func show(message: String, controller: UIViewController) {
        
        // Set up the label
        let toastLabel = UILabel()
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font.withSize(12.0)
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        
        toastLabel.backgroundColor = UIColor(white: 0.1, alpha: 0.75)
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds  =  true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        controller.view.addSubview(toastLabel)
        
        // Constraints for the label
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor, constant: 8.0),
            toastLabel.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -8.0),
            toastLabel.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor, constant: -72.0),
        ])
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {_ in
            toastLabel.removeFromSuperview()
        })
    }
    
    static func getAlertController(titled title: String, reading message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                          style: .default,
                          handler: { _ in
                            os_log(.debug, "The \"OK\" alert occured.")
        }))
        return alert
    }
}
