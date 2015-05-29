//
//  OSTextField.swift
//  Belphegor
//
//  Created by Sauron Black on 5/11/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

import UIKit

class OSTextField: UITextField
{
    var edgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return super.textRectForBounds(UIEdgeInsetsInsetRect(bounds, edgeInsets))
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return super.editingRectForBounds(UIEdgeInsetsInsetRect(bounds, edgeInsets))
    }
}
