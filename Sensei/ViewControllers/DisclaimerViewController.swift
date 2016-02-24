//
//  DisclaimerViewController.swift
//  Sensei
//
//  Created by Sergey Sheba on 2/17/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class DisclaimerViewController: UIViewController {

    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomSpeechBubbleConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightSpeechBubbleConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        var rightInset: CGFloat = 0
        
        switch (screenHeight) {
            case 568: rightInset = 70.0 //iphone 5s
            case 667: rightInset = 80.0 //iphone 6s
            case 736: rightInset = 90.0 //iphone 6sPlus
            default: rightInset = 60.0 //iphone 4s
        }
        
        let senseiMoreTopBarHeight: CGFloat = 31.0
        let collectionViewAffVisButtonSpace: CGFloat = 35.0
        let affVizButtonHeightBottomSpace: CGFloat = 36.0
        let senseiHeight = ((screenHeight - senseiMoreTopBarHeight)/4 - collectionViewAffVisButtonSpace) * 0.8
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.bottomSpeechBubbleConstraint.constant = affVizButtonHeightBottomSpace + collectionViewAffVisButtonSpace + senseiHeight
            self.rightSpeechBubbleConstraint.constant = rightInset
            self.textView.setContentOffset(CGPointZero, animated: false)
            self.speechBubbleView.pointerPosition = SpeechBubbleView.PointerPosition.BottomRight
            self.speechBubbleView.showBubbleTip = true
        }
    }
    @IBAction func doneAction(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            TutorialManager.sharedInstance.nextUpgradedStep()
        })
    }
}
