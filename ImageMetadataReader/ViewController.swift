//
//  ViewController.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import UIKit
import Combine

class ViewController: UIViewController {

    @IBOutlet weak var imageViewer: ImageViewer!

    private var imageSubscriber: AnyCancellable!

    #if !targetEnvironment(macCatalyst)
    private var shareBarButtonItem: UIBarButtonItem!
    private var shareBarButtonImageSubscriber: AnyCancellable!
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        #if !targetEnvironment(macCatalyst)
        setupShareBarButtonItem()
        #endif

        _ = imageViewer.imageWell.becomeFirstResponder()

        title = "Caption-reading image well"

        imageSubscriber = imageViewer.imageWell.$image.sink {
            [weak self] image in
            if let image {
                self?.activityItemsConfiguration = UIActivityItemsConfiguration(objects: [image])
            } else {
                self?.activityItemsConfiguration = nil
            }
        }
    }
}

#if !targetEnvironment(macCatalyst)
extension ViewController {
    // Toolbar management
    // iOS apps use disappearing toolbar items, which look odd on the Mac.
    // Mac Catalyst apps use fixed toolbar items defined in the scene.

    private func setupShareBarButtonItem() {
        shareBarButtonItem = UIBarButtonItem(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), target: nil, action: #selector(share(_:)))

        shareBarButtonImageSubscriber = imageViewer.imageWell.$image.sink {
            [weak self] image in
            if let shareBarButtonItem = self?.shareBarButtonItem {
                if image != nil {
                    self?.navigationItem.setRightBarButtonItems([shareBarButtonItem], animated: true)
                } else {
                    self?.navigationItem.setRightBarButtonItems([], animated: true)
                }
            }
        }
    }

    @IBAction func share(_ sender: AnyObject) {
        if let item = sender as? UIBarButtonItem,
           let activityItemsConfiguration {
            let activityVC = UIActivityViewController(activityItemsConfiguration: activityItemsConfiguration)
            activityVC.popoverPresentationController?.sourceItem = item
            present(activityVC, animated: true)
        }
    }
}
#endif
