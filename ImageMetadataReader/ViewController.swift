//
//  ViewController.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageViewer: ImageViewer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = imageViewer.imageWell.becomeFirstResponder()
    }
}

