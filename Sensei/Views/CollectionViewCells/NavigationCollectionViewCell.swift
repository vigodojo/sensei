//
//  NavigationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol NavigationCollectionViewCellDelegate: class {
    
    func navigationCollectionViewCellDidBack(cell: NavigationCollectionViewCell)
}

class NavigationCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: NavigationCollectionViewCellDelegate?
    
    @IBAction func back() {
        delegate?.navigationCollectionViewCellDidBack(self)
    }
}
