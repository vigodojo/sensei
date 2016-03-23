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
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = "\tPlease read the following statement:\n\n\tThis application provides content for informational purposes only on an “as is” basis. It is based on the author’s research and own experience; however you and you alone are responsible for what you do with it. By using this application you agree that the authors are not responsible for any injury or harm caused by any practice of their advice.\n\n\tThis application is intended to be used as a general guide, and is not a substitute for professional help, nor does the information presume to deal with any mental disorders of any type. If you believe that you might suffer from any type of mental disorder, please seek the services of a professional.\n\n\tAll information is as accurate as the author can make it, but the author cannot guarantee that it is free of errors.\n\n\tThe author or authors will assume no liability or responsibility to any person or entity with respect to any loss or damage related directly or indirectly to the information on this website. The author disclaims all representations and warranties, express or implied.\n\n\tThe author will provide no remedy for any damage of any kind, including (without limitation) compensatory, direct, indirect, consequential, punitive or incidental damages arising from this site, including such from negligence, strict liability, or breach of warranty or contract, even after notice of the possibility of such damages."

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.textView.setContentOffset(CGPointZero, animated: false)
        }
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            TutorialManager.sharedInstance.nextUpgradedStep()
        })
    }
}
