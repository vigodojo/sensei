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
        static let SelectedButtonFont = UIFont(name: "HelveticaNeue-Bold", size: 17)!
        static let DefaultButtonFont = UIFont(name: "HelveticaNeue", size: 20)!
        static let SenseiViewControllerSegueIdentifier = "SwitchToSenseiViewController"
    }
    
    @IBOutlet weak var senseiTabButton: UIButton!
    @IBOutlet weak var moreTabButton: UIButton!
    @IBOutlet weak var containerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        UIApplication.sharedApplication().statusBarHidden = true
        self.performSegueWithIdentifier(Constants.SenseiViewControllerSegueIdentifier, sender: self)
    }

    @IBAction func openSensei() {
        senseiTabButton.selected = true
        moreTabButton.selected = false
        senseiTabButton.titleLabel?.font = Constants.SelectedButtonFont
        moreTabButton.titleLabel?.font = Constants.DefaultButtonFont
    }

    @IBAction func openMore() {
        senseiTabButton.selected = false
        moreTabButton.selected = true
        senseiTabButton.titleLabel?.font = Constants.DefaultButtonFont
        moreTabButton.titleLabel?.font = Constants.SelectedButtonFont
    }
}

