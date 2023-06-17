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

    // Image and image view state

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

        let dragInteraction = UIDragInteraction(delegate: self)
        self.addInteraction(dragInteraction)
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

    @IBAction func tapped(_ sender: Any?) {
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

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(delete(_:)):
            return (self.image != nil)
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override func delete(_ sender: Any?) {
        self.image = nil
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
                // Open in place is available. The first type is the native file type.
                _ = ip.loadFileRepresentation(for: oipType, openInPlace: true) {
                    URL, isInPlace, error in
                    if let URL {
                        var retvalImage: UIImage?  = nil
                        var retvalComment: String? = nil
                        var error: NSError? = nil
                        NSFileCoordinator().coordinate(readingItemAt: URL, error: &error) { actualURL in
                            if let image = UIImage(contentsOf: actualURL) {
                                retvalImage = image
                                if let comment: String? = actualURL.extendedAttributeObject(name: "com.apple.metadata:kMDItemFinderComment") {
                                    retvalComment = comment
                                }
                            }
                        }
                        completionHandler(retvalImage, retvalComment)
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

// Context menu
extension ImageWell: UIContextMenuInteractionDelegate
{
    private static let contextMenuIdentifier = UIMenu.Identifier(rawValue: "context")

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider:  { elements in
            if let editMenu = elements.first as? UIMenu {
                var editMenuChildren = editMenu.children
                editMenuChildren.append(
                    UICommand(title: "Delete", action: #selector(self.delete(_:)))
                )
                let newMenu = editMenu.replacingChildren(editMenuChildren)
                var newElements = elements
                newElements[0] = newMenu
                return UIMenu(children: newElements)
            } else {
                return UIMenu(children: elements)
            }
        })
    }
}

// Drag
extension ImageWell: UIDragInteractionDelegate
{
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        if let image {
            return [UIDragItem(itemProvider: NSItemProvider(object: image))]
        } else {
            return []
        }
    }
}
