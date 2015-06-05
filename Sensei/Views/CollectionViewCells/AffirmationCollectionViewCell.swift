//
//  AffirmationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol AffirmationCollectionViewCellDelegate: class {
    
    func affirmationCollectionViewCellDidChange(cell: AffirmationCollectionViewCell)
}

class AffirmationCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var textView: UITextView!
    weak var delegate: AffirmationCollectionViewCellDelegate?
}

// MARK: - UITextViewDelegate

extension AffirmationCollectionViewCell: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        delegate?.affirmationCollectionViewCellDidChange(self)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
