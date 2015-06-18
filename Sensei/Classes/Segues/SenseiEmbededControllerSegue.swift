//
//  SenseiEmbededControllerSegue.swift
//  Sensei
//
//  Created by Sauron Black on 6/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiEmbededControllerSegue: UIStoryboardSegue {
   
    override func perform() {
        assert((sourceViewController as? SenseiNavigationControllerConteiner) != nil, "Source view controller must be a class SenseiNavigationControllerConteiner")
        if let sourceViewController = sourceViewController as? SenseiNavigationControllerConteiner, destinationViewController = destinationViewController as? UIViewController {
            sourceViewController.embededController = destinationViewController
        }
    }
    
}
