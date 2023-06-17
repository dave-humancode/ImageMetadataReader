//
//  UIImageUtilities.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import Foundation
import UIKit

extension UIImage {
    /// Load an image from the contents of a file URL
    convenience init?(contentsOf URL: URL) {
        do {
            let data = try Data(contentsOf: URL)
            self.init(data: data)
        } catch {
            return nil
        }
    }
}
