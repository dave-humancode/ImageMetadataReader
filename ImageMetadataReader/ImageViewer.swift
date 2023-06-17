//
//  ImageViewer.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import Foundation
import UIKit
import Combine

/// An image well paired with a caption viewer
class ImageViewer: UIView {
    let imageWell: ImageWell
    let captionView: UILabel
    var captionSubscription: AnyCancellable!
    var stackView: UIStackView!

    private func _init() {
        captionView.numberOfLines = 0
        captionView.font = UIFont.preferredFont(forTextStyle: .caption1)

        let paddedCaptionView = UIView()
        paddedCaptionView.addSubviewToFit(captionView, padding: 8.0)

        stackView = UIStackView(arrangedSubviews: [imageWell, paddedCaptionView])
        stackView.axis = .vertical
        stackView.spacing = 8.0
        imageWell.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        imageWell.heightAnchor.constraint(equalToConstant: 300).isActive = true
        self.addSubviewToFit(stackView, padding: 0)

        captionSubscription = imageWell.$comment.sink {
            [weak self] string in
            self?.captionView.text = string
        }
    }

    override init(frame: CGRect) {
        imageWell = ImageWell()
        captionView = UILabel()
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        imageWell = ImageWell()
        captionView = UILabel()
        super.init(coder: coder)
        _init()
    }

    override var intrinsicContentSize: CGSize { get { stackView.intrinsicContentSize }}
}
