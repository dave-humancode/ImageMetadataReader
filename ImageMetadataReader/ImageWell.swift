//
//  ImageWell.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class ImageWell: UIView {
    static let cornerRadius = 24.0

    // Image well

    @Published
    var image: UIImage? {
        didSet {
            if let image {
                let imageView = UIImageView(image: image)
                self.imageView = imageView
                // Make image available for copying
                activityItemsConfiguration = UIActivityItemsConfiguration(objects: [image])
            } else {
                self.imageView = nil
                activityItemsConfiguration = nil
            }
        }
    }

    private var imageView: UIImageView? {
        willSet {
            if let imageView {
                imageView.removeFromSuperview()
            }
        }
        didSet {
            if let imageView {
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
                addSubviewToFit(imageView, padding: 0)
                isLabelVisible = false
            } else {
                isLabelVisible = true
            }
        }
    }

    // Empty state

    private let label: UILabel
    private var isLabelVisible: Bool {
        didSet {
            if isLabelVisible {
                label.alpha = 1.0
            } else {
                label.alpha = 0.0
            }
            setNeedsDisplay()
        }
    }

    static let lineThickness = 6.0
    static let padding = 12.0
    var lineColor: UIColor { get { isFirstResponder ? .systemGray : .systemGray2 }}

    // Comments

    @Published
    var comment: String?

    // MARK: Initialization

    private func _init() {
        self.backgroundColor = UIColor.systemBackground
        self.layer.cornerRadius = ImageWell.cornerRadius
        self.clipsToBounds = true

        label.text = "Drop or paste images here"
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToFit(label, padding: ImageWell.padding)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textColor = UIColor.systemGray

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tapGR)

        pasteConfiguration = UIPasteConfiguration(forAccepting: UIImage.self)

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(contextMenuInteraction)
    }

    override init(frame: CGRect) {
        label = UILabel()
        isLabelVisible = true
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        label = UILabel()
        isLabelVisible = true
        super.init(coder: coder)
        _init()
    }

    // MARK: Layout

    override var intrinsicContentSize: CGSize { get { CGSize(width: 300.0, height: 300.0) }}

    // MARK: Drawing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle, compatibleWith: traitCollection)
    }

    override func draw(_ rect: CGRect) {
        if (isLabelVisible) {
            let gc = UIGraphicsGetCurrentContext()!
            let insetAmount = ImageWell.lineThickness / 2.0
            let pathRect = bounds.inset(by: UIEdgeInsets(top: insetAmount, left: insetAmount, bottom: insetAmount, right: insetAmount))
            let cornerRadius = ImageWell.cornerRadius - ImageWell.lineThickness / 2.0
            let path = CGPath(roundedRect: pathRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            gc.setStrokeColor(lineColor.cgColor)
            gc.setLineWidth(ImageWell.lineThickness)
            gc.setLineDash(phase: 0, lengths: [15.0, 5.0])
            gc.addPath(path)
            gc.strokePath()
        }
    }

    // MARK: Event handling

    override var canBecomeFirstResponder: Bool { get { true }}
    override var canBecomeFocused: Bool { get { true }}

    @IBAction func tapped(_ sender: AnyObject) {
        _ = becomeFirstResponder()
    }

    override func becomeFirstResponder() -> Bool {
        let retval = super.becomeFirstResponder()
        setNeedsDisplay()
        return retval
    }

    override func resignFirstResponder() -> Bool {
        let retval = super.resignFirstResponder()
        setNeedsDisplay()
        return retval
    }

    // MARK: Paste/drop

    override func paste(itemProviders: [NSItemProvider]) {
        if let ip = itemProviders.first,
            ip.canLoadObject(ofClass: UIImage.self) {

            // Strong self reference is OK. This is a one-shot completion handler
            let completionHandler: (UIImage?, String?) -> Void = { image, comment in
                DispatchQueue.main.async {
                    self.image = image
                    self.comment = comment
                }
            }

            // Find representation that can be opened in place. This indicates
            // the origin of the drop is a file.
            let oipTypes = ip.registeredContentTypesForOpenInPlace
            if let oipType = oipTypes.first {
                // Open in place is available. The first type is usually the best
                _ = ip.loadFileRepresentation(for: oipType, openInPlace: true) {
                    URL, isInPlace, error in
                    if let URL, let image = UIImage(contentsOf: URL) {
                        let comment: String? = URL.extendedAttributeObject(name: "com.apple.metadata:kMDItemFinderComment")
                        completionHandler(image, comment)
                    } else {
                        completionHandler(nil, nil)
                    }
                }
            } else {
                // No open in place, just load the image
                ip.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        completionHandler(image, nil)
                    } else {
                        completionHandler(nil, nil)
                    }
                }
            }
        }
    }
}

// Context menus
extension ImageWell: UIContextMenuInteractionDelegate
{
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider:  { elements in
            return UIMenu(children: elements)
        })
    }
}
