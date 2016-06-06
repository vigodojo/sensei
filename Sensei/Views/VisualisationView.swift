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
    @IBOutlet weak var noImageSelectedLabel: UILabel!
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
                    editButtonHidden = true
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
            noImageSelectedLabel.hidden = (newValue != nil)
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
            /*
            Commenter relative to:
            https://trello.com/c/pYOD8AIc/27-please-remove-the-placeholder-text-from-visualization
            
            placeholderLabel.hidden = !newValue.isEmpty
            */
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
        
        /*
        Commenter relative to:
        https://trello.com/c/pYOD8AIc/27-please-remove-the-placeholder-text-from-visualization
        
        setupPlaceholderLabel()
        */

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
    
    func configureWithText(text: String, image: UIImage?, number: NSNumber) {
        editButtonHidden = image == nil
        self.image = image
        noImageSelectedLabel.text = "Slot \(number) is empty.\nPlease tap the camera icon to create a new visualization"
        if text.isEmpty {
            self.currentFontSize = maxFontSize
            self.text = text
        } else if image != nil {
            if let fontSize = fontSizeForText(text) {
                self.currentFontSize = fontSize
                self.text = text
            } else {
                self.currentFontSize = Visualization.MinFontSize
                self.text = shrinkText(text)
            }
        } else {
            self.text = text
        }
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == TextViewContentSizeContext {
            if let contentSize = (change?[NSKeyValueChangeNewKey] as? NSValue)?.CGSizeValue() {
                updateTextViewInsetsForContentSize(contentSize)
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Private
    
    private func shrinkText(text: String) -> String {
        let maxHeight = maxTextHeight
        let size = CGSizeMake(CGRectGetWidth(textView.frame), CGFloat.max)
        let options: NSStringDrawingOptions = ([NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading])
        let attributes = Visualization.outlinedTextAttributesWithMinFontSize()
        var height = CGRectGetHeight((text as NSString).boundingRectWithSize(size, options: options, attributes: attributes, context: nil))
        var aText = text
        while height > maxHeight && !aText.isEmpty {
            aText = aText.substringToIndex(aText.endIndex.predecessor())
            height = CGRectGetHeight((aText as NSString).boundingRectWithSize(size, options: options, attributes: attributes, context: nil))
        }
        return aText
    }
    
    private func setupPlaceholderLabel() {
        let placeholderText = "ENTERED TEXT SUPER EMPOSED ON TOP OF IMAGE AT THE BOTTOM"
        let attributes = Visualization.outlinedTextAttributesWithFontSize(Visualization.MinFontSize, color: UIColor.lightTextColor())
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
            fontSize += 1
            size = NSAttributedString(string: someText, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size()
        }
        textView.attributedText = NSAttributedString(string: someText, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize))
        maxFontSize = fontSize
    }
    private func calculateMaxTextHeightForMinFontSize() {

        maxTextHeight
    }
    
    private func fontSizeForText(text: String) -> CGFloat? {
        let size = CGSizeMake(CGRectGetWidth(textView.frame), maxTextHeight)
        return Visualization.findFontSizeForText(text, textContainerSize: size, maxFontSize: maxFontSize)
    }
    
    // MARK: - IBActions
    
    @IBAction func takePhoto() {
        SoundController.playTock()
        delegate?.visualizationViewDidTakePhoto(self)
    }
    
    @IBAction func edit() {
        SoundController.playTock()
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
    
    /*
    Commenter relative to:
    https://trello.com/c/pYOD8AIc/27-please-remove-the-placeholder-text-from-visualization
    
    
    func textViewDidBeginEditing(textView: UITextView) {
        placeholderLabel.hidden = true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholderLabel.hidden = !textView.text.isEmpty
    }
    */
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            mode = .Default
            return false
        } else if let aRange = textView.text.rangeFromNSRange(range) {
            let resultingText = textView.text.stringByReplacingCharactersInRange(aRange, withString: text)
            if let fontSize = fontSizeForText(resultingText) {
                if fontSize != currentFontSize {
                    currentFontSize = fontSize
                    if text.isEmpty {
                        textView.attributedText = NSAttributedString(string: resultingText, attributes: Visualization.outlinedTextAttributesWithFontSize(currentFontSize))
                        textView.selectedRange = NSMakeRange(range.location + (text as NSString).length, 0)
                        return false
                    } else {
                        textView.font = UIFont.helveticaNeueBlackOfSize(fontSize)
                    }
                }
                return true
            }
            return false
        }
        return true
    }
}
