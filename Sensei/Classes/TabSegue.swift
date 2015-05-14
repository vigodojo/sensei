//
//  TabSegue.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol TabSegueProtocol: class {
    weak var containerView: UIView! { get set }
}

class TabSegue: UIStoryboardSegue {
    
    override func perform() {
        assert((sourceViewController as? TabSegueProtocol) != nil, "Source view controller must conform to TabSegueProtocol")
        if let sourceViewController = sourceViewController as? UIViewController, destinationViewController = destinationViewController as? UIViewController {
            for (_, child) in enumerate(sourceViewController.childViewControllers) {
                removeViewController(child as! UIViewController)
            }
            addChildViewController(destinationViewController, toSourceViewController: sourceViewController)
        }
    }
    
    func removeViewController(viewController: UIViewController) {
        viewController.willMoveToParentViewController(nil)
        viewController.removeFromParentViewController()
        viewController.view.removeFromSuperview()
    }
    
    func addChildViewController(child: UIViewController, toSourceViewController source: UIViewController) {
        source.addChildViewController(child)
        (source as! TabSegueProtocol).containerView.addSubview(child.view)
        child.view.frame = (sourceViewController as! TabSegueProtocol).containerView.bounds
        child.didMoveToParentViewController(source)
    }
}
