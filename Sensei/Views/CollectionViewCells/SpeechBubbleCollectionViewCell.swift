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
    @IBOutlet weak var textView: UITextView!
	@IBOutlet weak var speachBubleOffsetConstraint: NSLayoutConstraint!

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
            textView.attributedText = NSAttributedString(string: "", attributes: nil)
            textView.text = nil
            textView.text = newValue
        }
    }
    
    var attributedText: NSAttributedString {
        get {
            return textView.attributedText
        }
        set {
            textView.text = nil
            textView.attributedText = NSAttributedString(string: "", attributes: nil)
            textView.attributedText = newValue
        }
    }
    
    var visualization: Visualization?
    
    var closeButtonHidden: Bool {
        get {
            return closeButton.hidden
        }
        set {
            closeButton.hidden = newValue
        }
    }

//	var speachBubleOffset: CGFloat {
//		get {
//			return speachBubleOffsetConstraint.constant
//		}
//		set {
//			speachBubleOffsetConstraint.constant = newValue
//		}
//	}
    
    var delegate: SpeechBubbleCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
    }
    
    @IBAction func close() {
        delegate?.speechBubbleCollectionViewCellDidClose(self)
    }

	class func sizeForText(text: String, maxWidth: CGFloat, type: BubbleCollectionViewCellType = .Sensei) -> CGSize {
		let topAndBottomConstraints: CGFloat = 16
		let leadingAndTrailingConstraints: CGFloat
		switch type {
			case .Sensei, .Confirmation: leadingAndTrailingConstraints = 35
			case .Me: leadingAndTrailingConstraints = 25
		}
		let attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
		let constraintingSize = CGSize(width: maxWidth - leadingAndTrailingConstraints, height: CGFloat.max)
		let textSize = attributedText.boundingRectWithSize(constraintingSize, options: [.UsesLineFragmentOrigin, .UsesFontLeading], context: nil).size

		return CGSize(width: textSize.width + leadingAndTrailingConstraints, height: textSize.height + topAndBottomConstraints)
	}
    
    func showCloseButton(show: Bool) {
        if let closeButton = closeButton {
            closeButton.hidden = !show
        }
    }
}

extension SpeechBubbleCollectionViewCell: UITextViewDelegate {
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL == LinkToVisualization {
            NSNotificationCenter.defaultCenter().postNotificationName(TutorialBubbleCollectionViewCell.Notifications.VisualizationTap, object: visualization)
            return false
        }
        return true
    }
}
