//
//  EditVisualizationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/22/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

let TextViewContentSizeContext = UnsafeMutablePointer<Void>()

class EditVisualizationCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        textView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: TextViewContentSizeContext)
    }
    
    deinit {
        textView.removeObserver(self, forKeyPath: "contentSize", context: TextViewContentSizeContext)
    }
    
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
    
    @IBAction func delete() {
        
    }
}
