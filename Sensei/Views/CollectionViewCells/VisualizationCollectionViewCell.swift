//
//  VisualizationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/22/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

let VisualizationCollectionViewCellTextViewContentSizeContext = UnsafeMutablePointer<Void>()

enum VisualizationCollectionViewCellMode {
    case Default
    case Editing
}

protocol VisualizationCollectionViewCellDelegate: class {
    
    func visualizationCollectionViewCellDidTakePhoto(cell: VisualizationCollectionViewCell)
    func visualizationCollectionViewCellDidBeginEditing(cell: VisualizationCollectionViewCell)
    func visualizationCollectionViewCellDidEndEditing(cell: VisualizationCollectionViewCell)
    func visualizationCollectionViewCellDidDelete(cell: VisualizationCollectionViewCell)
    func visualizationCollectionViewCellDidChange(cell: VisualizationCollectionViewCell)
}

class VisualizationCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var textView: PlaceholderedTextView!
    
    private let outlinedTextAttributes: [String: AnyObject] = [NSStrokeColorAttributeName: UIColor.whiteColor(),
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSStrokeWidthAttributeName: NSNumber(double:-6.0),
        NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 13.0)!,
    ]
    
    var mode = VisualizationCollectionViewCellMode.Default {
        didSet {
            switch mode {
                case .Editing:
                    textView.userInteractionEnabled = true
                    delegate?.visualizationCollectionViewCellDidBeginEditing(self)
                    editButton.setTitle("DELETE", forState: UIControlState.Normal)
                case .Default:
                    textView.userInteractionEnabled = false
                    delegate?.visualizationCollectionViewCellDidEndEditing(self)
                    editButton.setTitle("EDIT", forState: UIControlState.Normal)
                    textView.resignFirstResponder()
                
                }
        }
    }
    
    var text: String {
        get {
            return textView.text
        } set {
            if !newValue.isEmpty {
                textView.attributedText = NSAttributedString(string: newValue, attributes: outlinedTextAttributes)
                textView.textAlignment = NSTextAlignment.Center
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
    
    weak var delegate: VisualizationCollectionViewCellDelegate?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        textView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: TextViewContentSizeContext)
        text = "ENTERED TEXT SUPER EMPOSED ON TOP OF IMAGE AT THE BOTTOM"
//        text = ""
    }
    
    deinit {
        textView.removeObserver(self, forKeyPath: "contentSize", context: TextViewContentSizeContext)
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == TextViewContentSizeContext {
            if let contentSize = (change[NSKeyValueChangeNewKey] as? NSValue)?.CGSizeValue() where contentSize.height < CGRectGetHeight(textView.frame) {
                let offset = CGRectGetHeight(textView.frame) - contentSize.height
                textView.contentInset = UIEdgeInsets(top: offset, left: 0, bottom: 0, right: 0)
                println("Neue Content Size = \(contentSize), offset = \(offset)")
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Private
    
    // MARK: - IBActions
    
    @IBAction func takePhoto() {
        delegate?.visualizationCollectionViewCellDidTakePhoto(self)
    }
    
    @IBAction func edit() {
        switch mode {
            case .Default:
                mode = .Editing
            case .Editing:
                delegate?.visualizationCollectionViewCellDidDelete(self)
                mode = .Default
        }
    }
}

// MARK: - UITextViewDelegate

extension VisualizationCollectionViewCell: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        delegate?.visualizationCollectionViewCellDidChange(self)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            mode = .Default
            return false
        }
        return true
    }
}
