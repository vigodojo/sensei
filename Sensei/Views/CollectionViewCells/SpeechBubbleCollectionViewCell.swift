//
//  SpeechBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

let RightSpeechBubbleCollectionViewCellNibName = "RightSpeechBubbleCollectionViewCell"
let RightSpeechBubbleCollectionViewCellIdentifier = "RightSpeechBubbleCollectionViewCell"
let LeftSpeechBubbleCollectionViewCellNibName = "LeftSpeechBubbleCollectionViewCell"
let LeftSpeechBubbleCollectionViewCellIdentifier = "LeftSpeechBubbleCollectionViewCell"

enum BubbleCollectionViewCellType {
    case Sensei
    case Me
    case Confirmation
}

protocol SpeechBubbleCollectionViewCellDelegate: class {
    
    func speechBubbleCollectionViewCellDidClose(cell: SpeechBubbleCollectionViewCell)
}

class IrresponsibleTextView: UITextView {
    
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
}

class SpeechBubbleCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let DefaultTextViewLeadingSpace: CGFloat = 8
        static let DefaultTextViewTrailingSpace: CGFloat = 28
    }
    
    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!

    class func reuseIdetifierForBubbleCellType(type: BubbleCollectionViewCellType) -> String {
        switch type {
            case .Sensei, .Confirmation: return "RightSpeechBubbleCollectionViewCell"
            case .Me: return "LeftSpeechBubbleCollectionViewCell"
        }
    }
    
    var text: String {
        get {
            return textView.text
        }
        set {
            textView.text = nil
            textView.text = newValue
        }
    }
    
    var closeButtonHidden: Bool {
        get {
            return closeButton.hidden
        }
        set {
            closeButton.hidden = newValue
        }
    }
    
    var delegate: SpeechBubbleCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
    }
    
    @IBAction func close() {
        delegate?.speechBubbleCollectionViewCellDidClose(self)
    }
}
