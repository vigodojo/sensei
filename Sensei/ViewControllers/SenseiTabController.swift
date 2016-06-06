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
    var maskBlack: UIView?
    
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiTabController.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: nil) { [unowned self] notification in
            if SenseiManager.sharedManager.shouldShowSenseiScreen() {
                if self.navigationController?.viewControllers.last != self {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                }
                if self.currentViewController != self.viewControllers.first {
                    self.showSenseiViewController()
                }
            } else if let mask = self.maskBlack {
                mask.removeFromSuperview()
            }
            (self.viewControllers.first as? SenseiViewController)?.didBecomeActive()
            SenseiManager.sharedManager.saveLastActiveTime()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self]notification in
            (self.viewControllers.first as? SenseiViewController)?.didEnterBackground()
//            self.tutorialViewController?.splashMaskImageView.hidden = false
            if self.maskBlack == nil {
                self.maskBlack = UIView(frame: UIScreen.mainScreen().bounds)
                self.maskBlack!.backgroundColor = UIColor.blackColor()
            }
            if let mask = self.maskBlack {
                UIApplication.sharedApplication().delegate?.window!?.addSubview(mask)
            }
        }
    }

    func reachabilityChanged(notifiication: NSNotification) {
        let reachability = notifiication.object as! Reachability
        if reachability.isReachable() {
            if !APIManager.sharedInstance.logined {
                let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
                let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
                APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone, handler: nil)
            } else {
                OfflineManager.sharedManager.synchronizeWithServer()
            }
        }
    }
    
    deinit {
        removeTutorialObservers()
    }
    
    // MARK: - Public
    
    override func addTutorialObservers() {
        super.addTutorialObservers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiTabController.didFinishTutorialNotificatin(_:)), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiTabController.didFinishUpgradeNotificatin(_:)), name: TutorialManager.Notifications.DidFinishUpgrade, object: nil)
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
                (viewControllers[0] as! SenseiViewController).removeAllExeptLessons()
                APIManager.sharedInstance.clearHistory(nil)
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
                self.enableControls(tutorialStep.enabledContols)
                break
            default:
                break
        }
    }
    
    override func enableControls(controlNames: [String]?) {
        var delay: Float = 0
        if let names = controlNames where names.contains(ControlNames.SenseiTab) || names.contains(ControlNames.MoreTab) {
            delay = 2.0
        }
        self.dispatchInMainThreadAfter(delay: delay) {
            if !TutorialManager.sharedInstance.upgradeCompleted {
                self.senseiTabButton.userInteractionEnabled = controlNames?.contains(ControlNames.SenseiTab) ?? true
                self.moreTabButton.userInteractionEnabled = controlNames?.contains(ControlNames.MoreTab) ?? true
            }
        }
    }
    
    // MARK: - IBAction

    @IBAction func openSensei() {
        SoundController.playTock()
        showSenseiViewController()
    }

    @IBAction func openMore() {
        SoundController.playTock()
        showSettingsViewController()
    }
}

