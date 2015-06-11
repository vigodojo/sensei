//
//  TextImageView.swift
//  Sensei
//
//  Created by Sauron Black on 6/10/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class TextImageView: UIView {
    
    private class AttributedTextLayer: CALayer {
        
        var attributedText: NSAttributedString? {
            didSet {
                setNeedsDisplay()
            }
        }
        
        private override func drawInContext(ctx: CGContext!) {
            if let text = attributedText {
                let textSize = textSizeForText(text)
                let textOrigin = textOriginForTextSize(textSize)
                let rect = CGRect(origin: textOrigin, size: textSize)
                
                UIGraphicsPushContext(ctx)
                text.drawInRect(rect)
                UIGraphicsPopContext()
            }
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

    private weak var imageView: UIImageView!
    private weak var textLayer: AttributedTextLayer!

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    var attributedText: NSAttributedString? {
        didSet {
            textLayer.attributedText = attributedText
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
        let aTextLayer = AttributedTextLayer()
        imageView.layer.addSublayer(aTextLayer)
        textLayer = aTextLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        textLayer.frame = bounds
    }
}
