//
//  SpeechBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

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
    
    private struct Constants {
        static let DefaultTitleLabelLeadingSpace: CGFloat = 8
        static let DefaultTitleLabelTrailingSpace: CGFloat = 48
        static let DefaultAccessoryItemsContainerHeight: CGFloat = 40
    }
    
    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var accessoryItemsContainerHeightConstraint: NSLayoutConstraint!
    
    var type = SpeechBubbleCollectionViewCellType.Sensei {
        didSet {
            titleLabelLeadingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
            titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelTrailingSpace
            accessoryItemsContainerHeightConstraint.constant = 0
            switch type {
                case .Sensei:
                    speechBubbleView.pointerPosition = .Right
                    closeButton.hidden = false
                case .Me:
                    speechBubbleView.pointerPosition = .Left
                    closeButton.hidden = true
                    titleLabelLeadingConstraint.constant = speechBubbleView.pointerSize.width + Constants.DefaultTitleLabelLeadingSpace
                    titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
                case .Confirmation:
                    speechBubbleView.pointerPosition = .Right
                    closeButton.hidden = true
                    accessoryItemsContainerHeightConstraint.constant = Constants.DefaultAccessoryItemsContainerHeight
            }
            setNeedsDisplay()
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
    }
    
    @IBAction func noAction() {
    }
}