//
//  UIViewUtilities.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import Foundation
import UIKit

extension UIView {
    func addSubviewToFit(_ view: UIView, padding: CGFloat) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: padding),
        ])
    }
}

