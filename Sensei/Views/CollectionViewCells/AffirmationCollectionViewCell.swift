//
//  AffirmationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

let AffirmationCollectionViewCellBoundsContext = UnsafeMutablePointer<Void>()

protocol AffirmationCollectionViewCellDelegate: class {
    
    func affirmationCollectionViewCellDidChange(cell: AffirmationCollectionViewCell)
    func affirmationCollectionViewCellDidDelete(cell: AffirmationCollectionViewCell)
}

class AffirmationCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let MinTextViewHeight: CGFloat = 48
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    weak var delegate: AffirmationCollectionViewCellDelegate?
    
    var text: String {
        get {
            return textView.text
        }
        set {
            textView.text = newValue
            textView.layoutIfNeeded()
            updateTextViewHeight()
        }
    }
    
    // MARK: - Private
    
    func updateTextViewHeight() {
        let height = textView.contentSize.height
        textViewHeightConstraint.constant = min(max(height, Constants.MinTextViewHeight), CGRectGetMaxY(textView.frame))
    }
    
    // MARK: - IBActions
    
    @IBAction func delete() {
        textView.resignFirstResponder()
        delegate?.affirmationCollectionViewCellDidDelete(self)
    }
}

// MARK: - UITextViewDelegate

extension AffirmationCollectionViewCell: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        if textView.contentSize.height != textViewHeightConstraint.constant {
            updateTextViewHeight()
        }
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
