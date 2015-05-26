//
//  EditVisualizationViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/22/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class EditVisualizationViewController: SenseiNavigationController {
    
    private struct Constants {
        static let EditVisualizationCellReuseIdentifier = "EditVisualizationCollectionViewCell"
        static let EditVisualizationCellHeight: CGFloat = 170
        static let InitialKeyboardHeight: CGFloat = 250
    }
    
    override var remainingHeight: CGFloat {
        return super.remainingHeight - keyboardHeight
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "Edit Visualization"
        }
    }
    
    var keyboardHeight = Constants.InitialKeyboardHeight
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupItems()
        addKeyboardObservers()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Private
    
    private func setupItems() {
        items.append(Item(reuseIdentifier: Constants.EditVisualizationCellReuseIdentifier, height: remainingHeight))
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        
    }
}
