//
//  PrivacyPolicyViewController.swift
//  Sensei
//
//  Created by Sergey Sheba on 3/29/17.
//  Copyright © 2017 ThinkMobiles. All rights reserved.
//

import UIKit

class PrivacyPolicyViewController: UIViewController {
    
    @IBOutlet weak var navigationView: NavigationView!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationView.delegate = self
        navigationView.titleLabel.text = "Privacy Policy".uppercaseString
        
        if let url = NSBundle.mainBundle().URLForResource("privacy_policy", withExtension: "html") {
            webView.loadRequest(NSURLRequest(URL: url))
        }
    }
}

extension PrivacyPolicyViewController: NavigationViewDelegate {
    func navigationViewDidBack(cell: NavigationView) {
        navigationController?.popViewControllerAnimated(true)
    }
}
