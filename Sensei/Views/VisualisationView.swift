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
    @IBOutlet weak var textView: PlaceholderedTextView!
    @IBOutlet weak var imageBounderingView: UIView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageContainerWidthConstraint: NSLayoutConstraint!
    
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
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(imageBounderingView.bounds), height: maxImageViewHeight))
            updateImageContainerViewWithBounds(rect)
            maxFontSize = newValue != nil ? calculateMaxFontSize(): Visualization.MinFontSize
        }
    }
    
    var text: String {
        get {
            return textView.text
        }
        set {
            if !newValue.isEmpty {
                textView.attributedText = NSAttributedString(string: newValue, attributes: Visualization.OutlinedTextAttributes)
            } else {
                textView.text = ""
            }
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
    
    var maxFontSize = Visualization.MinFontSize
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: TextViewContentSizeContext)
        text = "ENTERED TEXT SUPER EMPOSED ON TOP OF IMAGE AT THE BOTTOM"
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
    
    private func calculateMaxFontSize() -> CGFloat {
        let t1 = CACurrentMediaTime()
        let someText = "A"
        var fontSize = Visualization.MinFontSize
        let maxHeight = (imageContainerHeightConstraint.constant / CGFloat(6))
        var size = NSAttributedString(string: someText, attributes: Visualization.attributesForFontWithSize(fontSize)).size()
        while size.height < maxHeight {
            fontSize++
            size = NSAttributedString(string: someText, attributes: Visualization.attributesForFontWithSize(fontSize)).size()
        }
        let t2 = CACurrentMediaTime()
        println("calculateMaxFontSize = \((t2 - t1) * Double(1000))")
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
    
//    func textViewDidChange(textView: UITextView) {
//        let someText = "A"
//        var fontSize = Visualization.MinFontSize
//        var size = NSAttributedString(string: someText, attributes: Visualization.attributesForFontWithSize(fontSize)).size()
////        if textView
//    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            mode = .Default
            return false
        }
        return true
    }
}
