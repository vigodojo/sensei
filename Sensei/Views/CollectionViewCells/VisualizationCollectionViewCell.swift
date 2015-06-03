//
//  VisualizationCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/22/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol VisualizationCollectionViewCellDelegate: class {
    
    func visualizationCollectionViewCellDidTakePhoto(cell: VisualizationCollectionViewCell)
    func visualizationCollectionViewCellDidEdit(cell: VisualizationCollectionViewCell)
}

class VisualizationCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    
    private let outlinedTextAttributes = [NSStrokeColorAttributeName: UIColor.whiteColor(),
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSStrokeWidthAttributeName:-6.0]
    
    var text: String? {
        get {
            return textLabel.text
        } set {
            if let text = newValue {
                textLabel.attributedText = NSAttributedString(string: text, attributes: outlinedTextAttributes)
            } else {
                textLabel.text = ""
            }
        }
    }
    
    var editButtonHidden: Bool {
        get {
            return editButton.hidden
        }
        set {
            editButton.hidden = newValue
        }
    }
    
    weak var delegate: VisualizationCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    @IBAction func takePhoto() {
        delegate?.visualizationCollectionViewCellDidTakePhoto(self)
    }
    
    @IBAction func edit() {
        delegate?.visualizationCollectionViewCellDidEdit(self)
    }
}
