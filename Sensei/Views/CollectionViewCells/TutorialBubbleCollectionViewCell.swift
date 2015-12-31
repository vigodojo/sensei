//
//  TutorialBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 7/16/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol TutorialBubbleCollectionViewCellDelegate: class {
    
    func tutorialBubbleCollectionViewCellCanShowMoreMessages(cell: TutorialBubbleCollectionViewCell) -> Bool
    func tutorialBubbleCollectionViewCellDidYes(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNo(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNext(cell: TutorialBubbleCollectionViewCell)
}

class TutorialBubbleCollectionViewCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "TutorialBubbleCollectionViewCell"
    
    struct Notifications {
        static let NoAnswer = "TutorialBubbleCollectionViewCellNotificationsNoAnswer"
        static let YesAnswer = "TutorialBubbleCollectionViewCellNotificationsYesAnswer"
        static let AfirmationTap = "TutorialBubbleCollectionViewCellNotificationsAffirmatinTap"
        static let VisualizationTap = "TutorialBubbleCollectionViewCellNotificationsVisualizationTap"
    }

    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var controllsContainer: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var bouncedTop: Bool = false
    weak var delegate: TutorialBubbleCollectionViewCellDelegate?
    
    var type = BubbleCollectionViewCellType.Sensei {
        didSet {
            switch type {
                case .Sensei:
                    controllsContainer.hidden = true
                    nextButton.hidden = false
                    setArrowButtonVisibleIfNeeded(nil)
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
            textView.text = newValue
            textView.font = UIFont(name: "HelveticaNeue-Bold", size: 13.0)
            textView.contentOffset = CGPointZero
            print(textView.contentSize)
            print(textView.bounds)
            setArrowButtonVisibleIfNeeded(textView.contentSize.height < CGRectGetMaxY(textView.bounds))
        }
    }
    
    func append(text: String, autoscroll: Bool) {
        textView.appendText(text, autoscroll: autoscroll)
        setArrowButtonVisibleIfNeeded(nil)
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.delegate = self
		textView.textContainerInset = UIEdgeInsetsZero
		textView.textContainer.lineFragmentPadding = 0
        textView.alwaysBounceVertical = true
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
        textView.layoutIfNeeded()
        textView.dataDetectorTypes = UIDataDetectorTypes.All
        textView.selectable = true
        setArrowButtonVisibleIfNeeded(nil)
    }
    
    // MARK: - Private
    
    private func setArrowButtonVisibleIfNeeded(hidden: Bool?)
    {
        if let hideNeeded = hidden {
            nextButton.hidden = hideNeeded
        } else {
//            let height = textView.contentSize.height
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: CGFloat(MAXFLOAT)))
            nextButton.hidden = CGRectGetMaxY(textView.bounds) > size.height
        }
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

// MARK: - UIScrollViewDelegate

extension TutorialBubbleCollectionViewCell: UITextViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        setArrowButtonVisibleIfNeeded(scrollView.scrollViewDidScrollToBottom())
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView.scrollViewDidScrollToBottom() {
            delegate?.tutorialBubbleCollectionViewCellDidNext(self)
        }
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL == LinkToAppOnAppStore {
            UpgradeManager.sharedInstance.askForUpgrade()
            return false
        } else if URL == LinkToAffirmation {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.AfirmationTap, object: nil)
            return false
        } else if URL == LinkToVisualization {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.VisualizationTap, object: nil)
            return false
        }
        
        return true;
    }
}
