//
//  ViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/6/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol SenseiTabControllerDelegate: class {
    
    func senseiTabController(senseiTabController: SenseiTabController, shouldSelectViewController: UIViewController) -> Bool
}

class SenseiTabController: BaseViewController, TabSegueProtocol, UITabBarControllerDelegate {
    
    private struct ControlNames {
        static let SenseiTab = "SenseiTab"
        static let MoreTab = "MoreTab"
    }
    
    private struct Constants {
        static let SenseiViewControllerSegueIdentifier = "SwitchToSenseiViewController"
        static let MoreViewControllerSegueIdentifier = "SwitchToMoreViewController"
    }
    
    @IBOutlet weak var senseiTabButton: UIButton!
    @IBOutlet weak var moreTabButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var currentViewController: UIViewController?
    var viewControllers = [UIViewController]()
    weak var delegate: SenseiTabControllerDelegate?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        UIApplication.sharedApplication().statusBarHidden = true
        performSegueWithIdentifier(Constants.SenseiViewControllerSegueIdentifier, sender: self)
        performSegueWithIdentifier(Constants.MoreViewControllerSegueIdentifier, sender: self)
        
        showSenseiViewController()
        addTutorialObservers()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reachabilityChanged:"), name: ReachabilityChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: nil) { [unowned self] notification in
            if SenseiManager.sharedManager.shouldShowSenseiScreen() {
                if self.navigationController?.viewControllers.last != self {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                }
                if self.currentViewController != self.viewControllers.first {
                    self.showSenseiViewController()
                }
            }
            (self.viewControllers.first as? SenseiViewController)?.didBecomeActive()
            SenseiManager.sharedManager.saveLastActiveTime()
            UIApplication.sharedApplication().delegate?.window!?.subviews.last!.removeFromSuperview()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self]notification in
            (self.viewControllers.first as? SenseiViewController)?.didEnterBackground()

            let blackView = UIView(frame: UIScreen.mainScreen().bounds)
            blackView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().delegate?.window!?.addSubview(blackView)
        }
    }
    
    func reachabilityChanged(notifiication: NSNotification) {
        let reachability = notifiication.object as! Reachability
        
        var message = ""
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                message = "Wi Fi"
            } else {
                message = "Cellular"
            }

            let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
            let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
            APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone, handler: nil)
        } else {
            message = "Not Reachable"
        }
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    deinit {
        removeTutorialObservers()
    }
    
    // MARK: - Public
    
    override func addTutorialObservers() {
        super.addTutorialObservers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishTutorialNotificatin:"), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishUpgradeNotificatin:"), name: TutorialManager.Notifications.DidFinishUpgrade, object: nil)
    }
    
    func showSenseiViewController() {
        if !senseiTabButton.selected {
            if delegate == nil || delegate!.senseiTabController(self, shouldSelectViewController: viewControllers[0]) {
                senseiTabButton.selected = true
                moreTabButton.selected = false
                showChildViewController(viewControllers[0])
            }
        }
    }
    
    func showSettingsViewController() {
        if !moreTabButton.selected {
            if delegate == nil || delegate!.senseiTabController(self, shouldSelectViewController: viewControllers[0]) {
                senseiTabButton.selected = false
                moreTabButton.selected = true
                showChildViewController(viewControllers[1])
            }
        }
    }
    
    // MARK: - Private
    
    private func removeViewController(viewController: UIViewController) {
        viewController.willMoveToParentViewController(nil)
        viewController.removeFromParentViewController()
        viewController.view.removeFromSuperview()
    }
    
    private func showChildViewController(child: UIViewController) {
        if let currentViewController = currentViewController {
            removeViewController(currentViewController)
        }
        currentViewController = child
        addChildViewController(child)
        child.didMoveToParentViewController(self)
        containerView.addSubview(child.view)
        child.view.frame = containerView.bounds
    }
    
    // MARK: - Tutorial
    
    func didFinishTutorialNotificatin(notification: NSNotification) {
        self.senseiTabButton.userInteractionEnabled = true
        self.moreTabButton.userInteractionEnabled = true
    }
    
    func didFinishUpgradeNotificatin(notification: NSNotification) {
        self.senseiTabButton.userInteractionEnabled = true
        self.moreTabButton.userInteractionEnabled = true
    }
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        switch tutorialStep.screen {
            case .Sensei, .More:
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(tutorialStep.delayBefore) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.enableControls(tutorialStep.enabledContols)
                }
                break
            default:
                break
        }
    }
    
    override func enableControls(controlNames: [String]?) {
        senseiTabButton.userInteractionEnabled = controlNames?.contains(ControlNames.SenseiTab) ?? true
        moreTabButton.userInteractionEnabled = controlNames?.contains(ControlNames.MoreTab) ?? true
    }
    
    // MARK: - IBAction

    @IBAction func openSensei() {
        showSenseiViewController()
    }

    @IBAction func openMore() {
        showSettingsViewController()
    }
}

