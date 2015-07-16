//
//  TextCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 7/16/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class TextCollectionViewCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "TextCollectionViewCell"

    @IBOutlet weak var textView: UITextView!
    
    var text: String {
        get {
            return textView.text
        }
        set {
            textView.text = nil
            textView.text = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
    }

}
