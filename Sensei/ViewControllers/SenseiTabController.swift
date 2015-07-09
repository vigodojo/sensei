//
//  ViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/6/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiTabController: UIViewController, TabSegueProtocol {
    
    private struct Constants {
        static let SenseiViewControllerSegueIdentifier = "SwitchToSenseiViewController"
        static let MoreViewControllerSegueIdentifier = "SwitchToMoreViewController"
    }
    
    @IBOutlet weak var senseiTabButton: UIButton!
    @IBOutlet weak var moreTabButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var currentViewController: UIViewController?
    var viewControllers = [UIViewController]()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        UIApplication.sharedApplication().statusBarHidden = true
        performSegueWithIdentifier(Constants.SenseiViewControllerSegueIdentifier, sender: self)
        performSegueWithIdentifier(Constants.MoreViewControllerSegueIdentifier, sender: self)
        showSenseiViewController()
    }
    
    // MARK: - Public
    
    func showSenseiViewController() {
        if !senseiTabButton.selected {
            senseiTabButton.selected = true
            moreTabButton.selected = false
            showChildViewController(viewControllers[0])
        }
    }
    
    func showSettingsViewController() {
        if !moreTabButton.selected {
            senseiTabButton.selected = false
            moreTabButton.selected = true
            showChildViewController(viewControllers[1])
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
    
    // MARK: - IBAction

    @IBAction func openSensei() {
        showSenseiViewController()
    }

    @IBAction func openMore() {
        showSettingsViewController()
    }
}

