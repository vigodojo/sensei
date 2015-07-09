//
//  VisualisationView.swift
//  Sensei
//
//  Created by Sauron Black on 5/22/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import AVFoundation

let TextViewContentSizeContext = UnsafeMutablePointer<Void>()

let VisualizationCollectionViewCellTextViewContentSizeContext = UnsafeMutablePointer<Void>()

enum VisualizationViewMode {
    case Default
    case Editing
}

protocol VisualizationViewDelegate: class {
    
    func visualizationViewDidTakePhoto(visualisationView: VisualisationView)
    func visualizationViewDidBeginEditing(visualisationView: VisualisationView)
    func visualizationViewDidEndEditing(visualisationView: VisualisationView)
    func visualizationViewDidDelete(visualisationView: VisualisationView)
    func minPossibleHeightForVisualizationView(view: VisualisationView) -> CGFloat
}

class VisualisationView: UIView {
    
    static let ImageContainerEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 40, right: 0)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var imageBounderingView: UIView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageContainerWidthConstraint: NSLayoutConstraint!
    
    private var maxFontSize = Visualization.MinFontSize
    
    private var maxTextHeight: CGFloat {
        return NSAttributedString(string: "Ay\nAy\nAy", attributes: Visualization.outlinedTextAttributesWithMinFontSize()).size().height
    }
    
    var mode = VisualizationViewMode.Default {
        didSet {
            switch mode {
                case .Editing:
                    textView.userInteractionEnabled = true
                    editButton.setTitle("DELETE", forState: UIControlState.Normal)
                    editButtonHidden = false
                    cameraButton.hidden = true
                    textView.becomeFirstResponder()
                    delegate?.visualizationViewDidBeginEditing(self)
                case .Default:
                    textView.userInteractionEnabled = false
                    textView.resignFirstResponder()
                    editButton.setTitle("EDIT", forState: UIControlState.Normal)
                    cameraButton.hidden = false
                    delegate?.visualizationViewDidEndEditing(self)
                }
        }
    }
    
    private(set) var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(imageBounderingView.bounds), height: maxImageViewHeight))
            updateImageContainerViewWithBounds(rect)
            calculateMaxFontSize()
        }
    }
    
    private(set) var text: String {
        get {
            return textView.text
        }
        set {
            textView.attributedText = NSAttributedString(string: newValue, attributes: Visualization.outlinedTextAttributesWithFontSize(currentFontSize))
            placeholderLabel.hidden = !newValue.isEmpty
        }
    }
    
    var editButtonHidden: Bool {
        get {
            return editButton.hidden
        }
        set {
            editButton.hidden = newValue
        }
    }
    
    var minRequiredHeight: CGFloat {
        return CGRectGetHeight(bounds) - CGRectGetHeight(imageBounderingView.frame) + CGRectGetHeight(imageContainerView.frame)
    }
    
    weak var delegate: VisualizationViewDelegate? {
        didSet {
            calculateMaxImageViewHeight()
        }
    }
    
    var maxImageViewHeight: CGFloat = 0
    
    private(set) var currentFontSize = Visualization.MinFontSize
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: TextViewContentSizeContext)
        textView.textContainer.lineFragmentPadding = 0
        setupPlaceholderLabel()
        calculateMaxTextHeightForMinFontSize()
    }
    
    deinit {
        textView.removeObserver(self, forKeyPath: "contentSize", context: TextViewContentSizeContext)
    }
    
    // MARK: Public
    
    func updateImageContainerViewWithBounds(rect: CGRect) {
        if let image = image {
            let imageRect = AVMakeRectWithAspectRatioInsideRect(image.size, rect)
            imageContainerHeightConstraint.constant = CGRectGetHeight(imageRect)
            imageContainerWidthConstraint.constant = CGRectGetWidth(imageRect)
        } else {
            imageContainerHeightConstraint.constant = CGRectGetHeight(rect)
            imageContainerWidthConstraint.constant = CGRectGetWidth(rect)
        }
        imageContainerView.layoutIfNeeded()
        updateTextViewInsetsForContentSize(textView.contentSize)
    }
    
    func configureWithText(text: String, image: UIImage?, fontSize: CGFloat?) {
        editButtonHidden = image == nil
        self.image = image
        if let fontSize = fontSize {
            self.currentFontSize = fontSize
        } else {
            self.currentFontSize = maxFontSize
        }
        self.text = text
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == TextViewContentSizeContext {
            if let contentSize = (change[NSKeyValueChangeNewKey] as? NSValue)?.CGSizeValue() {
                updateTextViewInsetsForContentSize(contentSize)
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Private
    
    private func setupPlaceholderLabel() {
        let placeholderText = "ENTERED TEXT SUPER EMPOSED ON TOP OF IMAGE AT THE BOTTOM"
        let attributes = Visualization.outlinedTextAttributesWithFontSize(Visualization.MinFontSize, color: UIColor.darkGrayColor())
        placeholderLabel.attributedText = NSAttributedString(string: placeholderText, attributes: attributes)
    }
    
    private func updateTextViewInsetsForContentSize(contentSize: CGSize) {
        if  contentSize.height < CGRectGetHeight(textView.frame) {
            let offset = CGRectGetHeight(textView.frame) - contentSize.height
            textView.contentInset = UIEdgeInsets(top: offset, left: 0, bottom: 0, right: 0)
        }
    }
    
    private func calculateMaxImageViewHeight() {
        if let delegate = delegate {
            let minViewHeight = delegate.minPossibleHeightForVisualizationView(self)
            maxImageViewHeight = minViewHeight - VisualisationView.ImageContainerEdgeInsets.top - VisualisationView.ImageContainerEdgeInsets.bottom
        }
    }
    
    private func calculateMaxFontSize() {
        if image == nil {
            maxFontSize = Visualization.MinFontSize
            return
        }
        let someText = "A"
        var fontSize = Visualization.MinFontSize
        let maxHeight = (imageContainerHeightConstraint.constant / CGFloat(6))
        var size = NSAttributedString(string: someText, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size()
        while size.height < maxHeight {
            fontSize++
            size = NSAttributedString(string: someText, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size()
        }
        maxFontSize = fontSize
    }
    
    private func calculateMaxTextHeightForMinFontSize() {

        maxTextHeight
    }
    
    private func fontSizeForText(text: String) -> CGFloat? {
        return adjustFontSizeForText(text, startingFontSize: maxFontSize)
    }
    
    private func adjustFontSizeForText(text: String, startingFontSize: CGFloat) -> CGFloat? {
        var fontSize = startingFontSize
        var maxWidth = CGRectGetWidth(textView.frame)
        if fontSize > Visualization.MinFontSize {
            var width = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size().width
            while width >= maxWidth && fontSize > Visualization.MinFontSize {
                fontSize--
                width = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size().width
            }
        }
        if fontSize == Visualization.MinFontSize {
            let size = CGSizeMake(maxWidth, CGFloat.max)
            let height = CGRectGetHeight((text as NSString).boundingRectWithSize(size, options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: Visualization.outlinedTextAttributesWithMinFontSize(), context: nil))
            return height <= maxTextHeight ? fontSize: nil
        }
        return fontSize
    }
    
    // MARK: - IBActions
    
    @IBAction func takePhoto() {
        delegate?.visualizationViewDidTakePhoto(self)
    }
    
    @IBAction func edit() {
        switch mode {
            case .Default:
                mode = .Editing
            case .Editing:
                delegate?.visualizationViewDidDelete(self)
        }
    }
}

// MARK: - UITextViewDelegate

extension VisualisationView: UITextViewDelegate {
    
    func textViewDidBeginEditing(textView: UITextView) {
        placeholderLabel.hidden = true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholderLabel.hidden = !textView.text.isEmpty
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            mode = .Default
            return false
        } else if let aRange = textView.text.rangeFromNSRange(range) {
            let resultingText = textView.text.stringByReplacingCharactersInRange(aRange, withString: text)
            if let fontSize = fontSizeForText(resultingText) {
                if fontSize != currentFontSize {
                    currentFontSize = fontSize
                    textView.attributedText = NSAttributedString(string: resultingText, attributes: Visualization.outlinedTextAttributesWithFontSize(currentFontSize))
                    return false
                }
                return true
            }
//            if let fontSize = adjustFontSizeForText(resultingText, startingFontSize: currentFontSize) {
//                currentFontSize = fontSize
//                return true
//            }
            return false
        }
        return true
    }
}
