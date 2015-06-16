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
        static let BorderWidth: CFloat = 2.0
    }
    
    weak var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let label = UILabel()
        addSubview(label)
        textLabel = label
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = bounds
        clipsToBounds = true
        backgroundColor = UIColor.whiteColor()
        borderColor = Constants.BorderColor
    }
    
    override func didChangeValue(newValue: Float) {
        textLabel.text = "\(Int(newValue * 10.0))"
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
