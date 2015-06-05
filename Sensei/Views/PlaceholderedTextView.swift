//
//  PlaceholderedTextView.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class PlaceholderedTextView: UITextView {

    @IBInspectable var placeholder: String = ""
    @IBInspectable var placeholderColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable var normalTextColor: UIColor = UIColor.blackColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        text = text.isEmpty ? placeholder: text
    }
    
    override var text: String! {
        get {
            if super.text == placeholder {
                return ""
            } else {
                return super.text
            }
        }
        set {
            if !newValue.isEmpty && newValue != placeholder {
                super.text = newValue
                textColor = normalTextColor
            } else {
                super.text = placeholder
                textColor = placeholderColor
            }
            delegate?.textViewDidChange?(self)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        if super.text == placeholder {
            super.text = ""
            textColor = normalTextColor
            delegate?.textViewDidChange?(self)
        }
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        if super.text.isEmpty {
            super.text = placeholder
            textColor = placeholderColor
            delegate?.textViewDidChange?(self)
        }
        return super.resignFirstResponder()
    }
}
