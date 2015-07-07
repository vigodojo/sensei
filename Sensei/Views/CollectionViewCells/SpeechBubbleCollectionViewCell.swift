//
//  SpeechBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

let SpeechBubbleCollectionViewCellNibName = "SpeechBubbleCollectionViewCell"
let SpeechBubbleCollectionViewCellIdentifier = "SpeechBubbleCollectionViewCell"

enum SpeechBubbleCollectionViewCellType {
    case Sensei
    case Me
    case Confirmation
}

protocol SpeechBubbleCollectionViewCellDelegate: class {
    
    func speechBubbleCollectionViewCellDidClose(cell: SpeechBubbleCollectionViewCell)
    func speechBubbleCollectionViewCellDidYes(cell: SpeechBubbleCollectionViewCell)
    func speechBubbleCollectionViewCellDidNo(cell: SpeechBubbleCollectionViewCell)
}

class SpeechBubbleCollectionViewCell: UICollectionViewCell {
    
    struct Notifications {
        static let NoAnswer = "SpeechBubbleCollectionViewCellNotificationsNoAnswer"
        static let YesAnswer = "SpeechBubbleCollectionViewCellNotificationsYesAnswer"
    }
    
    private struct Constants {
        static let DefaultTitleLabelLeadingSpace: CGFloat = 8
        static let DefaultTitleLabelTrailingSpace: CGFloat = 48
        static let DefaultAccessoryItemsContainerHeight: CGFloat = 32
    }
    
    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var accessoryItemsContainerHeightConstraint: NSLayoutConstraint!
    
    var type = SpeechBubbleCollectionViewCellType.Sensei {
        didSet {
            titleLabelLeadingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
            titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelTrailingSpace
            accessoryItemsContainerHeightConstraint.constant = 0
            switch type {
                case .Sensei:
                    speechBubbleView.pointerPosition = .Right
                    closeButtonHidden = false
                case .Me:
                    speechBubbleView.pointerPosition = .Left
                    closeButtonHidden = true
                    titleLabelLeadingConstraint.constant = speechBubbleView.pointerSize.width + Constants.DefaultTitleLabelLeadingSpace
                    titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
                case .Confirmation:
                    speechBubbleView.pointerPosition = .Right
                    closeButtonHidden = true
                    accessoryItemsContainerHeightConstraint.constant = Constants.DefaultAccessoryItemsContainerHeight
            }
            setNeedsDisplay()
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
    }
    
    @IBAction func close() {
        delegate?.speechBubbleCollectionViewCellDidClose(self)
    }
    
    @IBAction func yesAction() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.YesAnswer, object: nil)
        delegate?.speechBubbleCollectionViewCellDidYes(self)
    }
    
    @IBAction func noAction() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.NoAnswer, object: nil)
        delegate?.speechBubbleCollectionViewCellDidNo(self)
    }
}