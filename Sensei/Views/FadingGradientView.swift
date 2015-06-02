//
//  FadingGradientView.swift
//  Sensei
//
//  Created by Sauron Black on 6/2/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class FadingGradientView: UIView {
    
    private struct Constants {
        static let Colors = [UIColor(hexColor: 0x545454).CGColor, UIColor.clearColor().CGColor]
    }
    
    private lazy var gradientLayer: CAGradientLayer = { [unowned self] in
        let gradient = CAGradientLayer()
        gradient.colors = Constants.Colors
        gradient.locations = [CGFloat(0.0), CGFloat(1.0)]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 0.7)
        self.layer.mask = gradient
        return gradient
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
