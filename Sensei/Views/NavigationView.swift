//
//  NavigationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol NavigationViewDelegate: class {
    
    func navigationViewDidBack(cell: NavigationView)
}

class NavigationView: UIView {
    
    private struct Constants {
        static let NibName = "NavigationView"
    }

    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: NavigationViewDelegate?
    
    // MARK: - Lifecycle
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    // MARK: - Private
    
    private func setup() {
        if let view = NSBundle.mainBundle().loadNibNamed(Constants.NibName, owner: self, options: nil).first as? UIView {
            addEdgePinnedSubview(view)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func back() {
        delegate?.navigationViewDidBack(self)
    }
}
