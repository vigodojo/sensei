//
//  MessageNumberCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SlotCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override var selected: Bool {
        didSet {
            layer.borderWidth = selected ? 2: 0
        }
    }
}
