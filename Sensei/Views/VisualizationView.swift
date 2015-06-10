//
//  VisualizationView.swift
//  Sensei
//
//  Created by Sauron Black on 6/10/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class VisualizationView: UIView {
    
    private struct Constants {
        static let NibName = "VisualizationView"
    }

    private weak var imageView: UIImageView!
    private weak var textLabel: UILabel!

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    var attributedText: NSAttributedString? {
        didSet {
            textLabel.attributedText = attributedText
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let anImageView = UIImageView()
        addSubview(anImageView)
        imageView = anImageView
        let aLabel = UILabel()
        aLabel.numberOfLines = 0
        addSubview(aLabel)
        textLabel = aLabel
//        let aTextView = TextView()
//        aTextView.backgroundColor = UIColor.clearColor()
//        addSubview(aTextView)
//        textView = aTextView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if let text = attributedText {
            let textSize = textSizeForText(text)
            let textOrigin = textOriginForTextSize(textSize)
            textLabel.frame = CGRect(origin: textOrigin, size: textSize)
        }
//        textView.frame = bounds
    }
    
    private func textSizeForText(text: NSAttributedString) -> CGSize {
        return text.boundingRectWithSize(CGSize(width: CGRectGetWidth(bounds), height: CGFloat.max), options: .UsesLineFragmentOrigin | .UsesFontLeading, context: nil).size
    }
    
    private func textOriginForTextSize(textSize: CGSize) -> CGPoint {
        var textOrigin = CGPointZero
        textOrigin.x = (CGRectGetWidth(bounds) - textSize.width) / 2.0
        textOrigin.y = CGRectGetHeight(bounds) - textSize.height
        return textOrigin
    }
}
