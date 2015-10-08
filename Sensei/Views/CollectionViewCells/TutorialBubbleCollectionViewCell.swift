//
//  TutorialBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 7/16/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol TutorialBubbleCollectionViewCellDelegate: class {
    
    func tutorialBubbleCollectionViewCellDidYes(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNo(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNext(cell: TutorialBubbleCollectionViewCell)
}

class TutorialBubbleCollectionViewCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "TutorialBubbleCollectionViewCell"
    
    struct Notifications {
        static let NoAnswer = "TutorialBubbleCollectionViewCellNotificationsNoAnswer"
        static let YesAnswer = "TutorialBubbleCollectionViewCellNotificationsYesAnswer"
    }

    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var controllsContainer: UIView!
    @IBOutlet weak var nextButton: UIButton!
	@IBOutlet weak var textView: UITextView!
    
    weak var delegate: TutorialBubbleCollectionViewCellDelegate?
    
    var type = BubbleCollectionViewCellType.Sensei {
        didSet {
            switch type {
                case .Sensei:
                    controllsContainer.hidden = true
                    nextButton.hidden = false
                case .Confirmation:
                    controllsContainer.hidden = false
                    nextButton.hidden = true
                default:
                    break
            }
        }
    }
    
    var text: String {
        get {
            return textView.text ?? ""
        }
        set {
            textView.text = nil
			textView.text = newValue
			textView.contentOffset = CGPointZero
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
		textView.textContainerInset = UIEdgeInsetsZero
		textView.textContainer.lineFragmentPadding = 0
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		textView.contentOffset = CGPointZero
	}

    // MARK: - Public
    
    func setAttributedString(attributedString: NSAttributedString) {
		textView.text = nil
		textView.attributedText = attributedString
		textView.contentOffset = CGPointZero
    }

    // MARK: - IBActions
    
    @IBAction func yesAnswer() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.YesAnswer, object: nil)
        delegate?.tutorialBubbleCollectionViewCellDidYes(self)
    }
    
    @IBAction func noAnswer() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.NoAnswer, object: nil)
        delegate?.tutorialBubbleCollectionViewCellDidNo(self)
    }
    
    @IBAction func next() {
		if CGRectGetMaxY(textView.bounds) >= textView.contentSize.height {
			delegate?.tutorialBubbleCollectionViewCellDidNext(self)
		} else {
			let height = CGRectGetHeight(textView.bounds)
			let offsetY = max(min(textView.contentSize.height - height, textView.contentOffset.y + height), 0)
			textView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
		}
    }
}
