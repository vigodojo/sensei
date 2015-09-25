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
        
        private var textRect: CGRect {
            return UIEdgeInsetsInsetRect(bounds, textInsets)
        }
        
        var textInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        var attributedText: NSAttributedString? {
            didSet {
                setNeedsDisplay()
            }
        }
        
        private override func drawInContext(ctx: CGContext) {
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
            return text.boundingRectWithSize(CGSize(width: CGRectGetWidth(textRect), height: CGFloat.max), options: [.UsesLineFragmentOrigin, .UsesFontLeading], context: nil).size
        }
        
        private func textOriginForTextSize(textSize: CGSize) -> CGPoint {
            var textOrigin = CGPointZero
            textOrigin.x = (CGRectGetWidth(textRect) - textSize.width) / 2.0 + textInsets.left
            textOrigin.y = CGRectGetHeight(textRect) - textSize.height + textInsets.top
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
    
    required init?(coder aDecoder: NSCoder) {
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
