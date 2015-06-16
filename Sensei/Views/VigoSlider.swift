//
//  VigoSlider.swift
//  Sensei
//
//  Created by Sauron Black on 6/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class VigoSlider: UIControl {
    
    struct Constants {
        static let DefaultThumbSize = CGSize(width: 25, height: 25)
    }
    
    @IBInspectable var minValue: Float = 0.0
    @IBInspectable var maxValue: Float = 1.0
    @IBInspectable var stepValue: Float = 0.1
    @IBInspectable var currentValue: Float = 0.0
    
    @IBInspectable var lineWidth: CGFloat = 1.0
    @IBInspectable var lineColor: UIColor = UIColor.blackColor()
    
    @IBOutlet private var thumbView: VigoSliderThumbView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setCustomThumbView(createDefaultTumbView())
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        println("awakeFromNib: \(thumbView)")
        if thumbView == nil {
            setCustomThumbView(createDefaultTumbView())
        }
    }

    override func drawRect(rect: CGRect) {
        println("Drawing code")
    }
    
    // MARK: Public
    
    func setCustomThumbView(view: VigoSliderThumbView) {
        if thumbView != nil {
            thumbView.removeFromSuperview()
        }
        addSubview(view)
        thumbView = view
        // TODO: Set Center
    }
    
    // MARK: Private
    
    private func createDefaultTumbView() -> VigoSliderThumbView {
        let view = VigoSliderThumbView(frame: CGRect(origin: CGPointZero, size: Constants.DefaultThumbSize))
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.DefaultThumbSize.width / 2.0
        return view
    }
}

class VigoSliderThumbView: UIView {
    
    func didChangeValue(newValue: Float) {}
}
