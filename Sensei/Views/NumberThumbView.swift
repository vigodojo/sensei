//
//  NumberThumbView.swift
//  Sensei
//
//  Created by Sauron Black on 6/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class NumberThumbView: VigoSliderThumbView {
    
    private struct Constants {
        static let BorderColor = UIColor(hexColor:0x315D7F)
        static let BorderWidth: CGFloat = 1.0
        static let Font = UIFont(name: "HelveticaNeue-Bold", size: 20.0)
    }
    
    weak var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let label = UILabel()
        label.font = Constants.Font
        label.text = "0"
        label.textAlignment = NSTextAlignment.Center
        addSubview(label)
        textLabel = label
        clipsToBounds = true
        backgroundColor = UIColor.whiteColor()
        borderColor = Constants.BorderColor
        layer.borderWidth = Constants.BorderWidth
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = bounds
        layer.cornerRadius = CGRectGetMidX(bounds)
    }
    
    override func didChangeValue(newValue: Int) {
        textLabel.text = "\(newValue)"
    }
}
