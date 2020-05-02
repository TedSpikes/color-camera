//
//  PhotoPreviewViewController.swift
//  Color Camera
//
//  Created by Fedor on 5/2/20.
//  Copyright © 2020 Fedor Kostylev. All rights reserved.
//

import UIKit

class PhotoPreviewViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBAction func discard(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
    }
    
    var previewImage: UIImage!
    
    init(withPreview previewImage: UIImage) {
        self.previewImage = previewImage
        super.init(nibName: "PhotoPreviewView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        self.imageView.image = self.previewImage
        self.imageView.contentMode = .scaleAspectFill
        super.viewDidLoad()
    }
    
}
