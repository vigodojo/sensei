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
    }
    
    deinit {
        removeTutorialObservers()
    }
    
    // MARK: - Public
    
    override func addTutorialObservers() {
        super.addTutorialObservers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishTutorialNotificatin:"), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
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
        enableControls(nil)
    }
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        switch tutorialStep.screen {
            case .Sensei, .More:
                enableControls(tutorialStep.enabledContols)
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

