//
//  TabSegue.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol TabSegueProtocol: class {
    
    var viewControllers: [UIViewController] { get set }
}

class TabSegue: UIStoryboardSegue {
    
    override func perform() {
        assert((sourceViewController as? TabSegueProtocol) != nil, "Source view controller must conform to TabSegueProtocol")
        if let sourceViewController = sourceViewController as? TabSegueProtocol {
            sourceViewController.viewControllers.append(destinationViewController)
        }
    }
}
