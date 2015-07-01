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
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        UIApplication.sharedApplication().statusBarHidden = true
        self.performSegueWithIdentifier(Constants.SenseiViewControllerSegueIdentifier, sender: self)
    }
    
    // MARK: - Public
    
    func showSenseiViewController() {
        if !senseiTabButton.selected {
            senseiTabButton.selected = true
            moreTabButton.selected = false
            performSegueWithIdentifier(Constants.SenseiViewControllerSegueIdentifier, sender: senseiTabButton)
        }
    }
    
    func showSettingsViewController() {
        if !moreTabButton.selected {
            senseiTabButton.selected = false
            moreTabButton.selected = true
            performSegueWithIdentifier(Constants.MoreViewControllerSegueIdentifier, sender: moreTabButton)
        }
    }
    
    // MARK: - IBAction

    @IBAction func openSensei() {
        showSenseiViewController()
    }

    @IBAction func openMore() {
        showSettingsViewController()
    }
}

