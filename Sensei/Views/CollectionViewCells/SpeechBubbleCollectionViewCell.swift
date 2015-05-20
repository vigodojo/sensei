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
}

protocol SpeechBubbleCollectionViewCellDelegate: class {
    
    func speechBubbleCollectionViewCellDidClose(cell: SpeechBubbleCollectionViewCell)
}

class SpeechBubbleCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let DefaultTitleLabelLeadingSpace: CGFloat = 8
        static let DefaultTitleLabelTrailingSpace: CGFloat = 48
    }
    
    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    
    var type = SpeechBubbleCollectionViewCellType.Sensei {
        didSet {
            switch type {
                case .Sensei:
                    speechBubbleView.pointerPosition = .Right
                    closeButton.hidden = false
                    titleLabelLeadingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
                    titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelTrailingSpace
                case .Me:
                    speechBubbleView.pointerPosition = .Left
                    closeButton.hidden = true
                    titleLabelLeadingConstraint.constant = speechBubbleView.pointerSize.width + Constants.DefaultTitleLabelLeadingSpace
                    titleLabelTrailingConstraint.constant = Constants.DefaultTitleLabelLeadingSpace
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
        if let delegate = delegate {
            delegate.speechBubbleCollectionViewCellDidClose(self)
        }
    }
}