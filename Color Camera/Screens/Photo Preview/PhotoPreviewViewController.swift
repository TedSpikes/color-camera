//
//  PhotoPreviewViewController.swift
//  Color Camera
//
//  Created by Ted on 5/2/20.
//  Copyright © 2020 Ted Kostylev. All rights reserved.
//

import UIKit

class PhotoPreviewViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBAction func discard(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
        guard let ciImage = self.previewImage.ciImage else { return }
        guard let cgImage = cgImage(from: ciImage) else { return }
        // Good god
        let newImage = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(newImage, self.delegate, #selector(ViewportViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    var previewImage: UIImage!
    weak private var delegate: ViewportViewController!
    
    init(delegate: ViewportViewController, withPreview previewImage: UIImage) {
        self.previewImage = previewImage
        self.delegate     = delegate
        
        super.init(nibName: "PhotoPreviewView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        self.imageView.image = self.previewImage
        self.imageView.contentMode = .scaleAspectFit
        super.viewDidLoad()
    }
    
    func cgImage(from ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
}
