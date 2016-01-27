//
//  SpeechBubbleView.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class SpeechBubbleView: UIView {
    
    enum PointerPosition: Int {
        case Left = 0
        case TopRight
        case BottomRight //this case added relative to https://trello.com/c/iZHV6sJt/37-tutorial-and-help-please-move-speech-bubble-pointer-to-the-top-right-of-the-bubble-see-comments
    }
    
    @IBInspectable var cornerRadius: CGFloat = 16 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var strokeColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var fillColor: UIColor = UIColor.whiteColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var pointerPositionNumber: Int = PointerPosition.TopRight.rawValue {
        didSet {
            pointerPosition = PointerPosition(rawValue: pointerPositionNumber) ?? .TopRight
        }
    }
    @IBInspectable var showBubbleTip: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var pointerPosition: PointerPosition = PointerPosition.TopRight {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var pointerSize: CGSize {
        return CGSize(width: (cornerRadius / 2.0) * 1.5, height: cornerRadius / 2.0)
    }
    
    
    override func drawRect(rect: CGRect) {
        let bodyPath: UIBezierPath
        switch pointerPosition {
			case .Left: bodyPath = bezierPathForLeft()
			case .TopRight: bodyPath = bezierPathForUpperRight()
            case .BottomRight: bodyPath = bezierPathForBottomRight()
        }
        bodyPath.lineWidth = lineWidth
//        strokeColor.setStroke()
        fillColor.setFill()
//        bodyPath.stroke()
        bodyPath.fill()
    }

    // MARK: - Draw Bottom Right Speech Bubble
    
    /**
    These methods have been returned from previous commit relative to task:
    https://trello.com/c/iZHV6sJt/37-tutorial-and-help-please-move-speech-bubble-pointer-to-the-top-right-of-the-bubble-see-comments
    Pointer position in RightSpeechBubbleCollectionViewCell has been changed to 'BottomRight';
    Pointer position in TutorialBubbleCollectionViewCell still stays on 'TopRight'
    */
    private func bezierPathForBottomRight() -> UIBezierPath {
        let aPointerSize = pointerSize
        let beziePath = UIBezierPath()
        let offset = lineWidth / 2.0
        let angle = RadiangsFromDegrees(55)
        let pointerOffset = cornerRadius - PoinOnCircleWithRadius(cornerRadius, angle: angle).x
        let rightEdgeOffset = cornerRadius + aPointerSize.width - pointerOffset + offset

        var point = CGPoint(x: cornerRadius + offset, y: cornerRadius + offset)
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(-M_PI_2), clockwise: true)
        point = beziePath.currentPoint
        point.x = CGRectGetWidth(bounds) - rightEdgeOffset
        beziePath.addLineToPoint(point)
        point.y = cornerRadius + offset
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(-M_PI_2), endAngle: 0.0, clockwise: true)
        point = beziePath.currentPoint


        if showBubbleTip {
            point.y = CGRectGetHeight(bounds) - cornerRadius*0.5 - offset
            beziePath.addLineToPoint(point)
            let pointerStart = point
            point.y -= cornerRadius * 0.5
            point.x -= cornerRadius

            let pointerEnd = PoinOnCircleWithRadius(cornerRadius, angle: angle, origin: point)
            addBottomRightPointerToBezierPath(beziePath, startPoint: pointerStart, endPoint: pointerEnd)
            beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: angle, endAngle: CGFloat(M_PI_2), clockwise: true)
        } else {
            point.y = CGRectGetHeight(bounds) - cornerRadius - offset
            beziePath.addLineToPoint(point)
            
            point.x = CGRectGetWidth(bounds) - rightEdgeOffset
            point.y = bounds.size.height - cornerRadius - offset
            beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(0.0), endAngle: CGFloat(M_PI_2), clockwise: true)
        }
        
        point.x = cornerRadius + offset
        point.y = CGRectGetHeight(bounds) - offset
        beziePath.addLineToPoint(point)
    
        point.y = bounds.size.height - cornerRadius - offset
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: CGFloat(M_PI), clockwise: true)
        
        beziePath.closePath()
        return beziePath
    }
    
    private func addBottomRightPointerToBezierPath(bezierPath: UIBezierPath, startPoint: CGPoint, endPoint: CGPoint) {
        let aPointerSize = pointerSize
        let xDelta = startPoint.x - endPoint.x
        let farPoint = CGPoint(x: endPoint.x + aPointerSize.width, y: startPoint.y + aPointerSize.height)
        var controlPoint = CGPoint(x: endPoint.x + xDelta * 1.2, y: startPoint.y + aPointerSize.height * 0.6)
        bezierPath.addQuadCurveToPoint(farPoint, controlPoint: controlPoint)
        controlPoint = CGPoint(x: endPoint.x + xDelta * 0.5, y: startPoint.y + aPointerSize.height * 0.95)
        bezierPath.addQuadCurveToPoint(endPoint, controlPoint: controlPoint)
    }
    
    // MARK: - Draw Upper Right Speech Bubble
    
    private func bezierPathForUpperRight() -> UIBezierPath {
        let aPointerSize = pointerSize
        let beziePath = UIBezierPath()
        let offset = lineWidth / 2.0
        let angle = RadiangsFromDegrees(-55)
        let pointerOffset = round(cornerRadius - PoinOnCircleWithRadius(cornerRadius, angle: angle).x)
        var point = CGPoint(x: cornerRadius + offset, y: cornerRadius + offset)
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(-M_PI_2), clockwise: true)
        point = beziePath.currentPoint
        point.x = CGRectGetWidth(bounds) - (cornerRadius + aPointerSize.width - pointerOffset + offset)
        beziePath.addLineToPoint(point)
        point.y = cornerRadius + offset
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(-M_PI_2), endAngle: angle, clockwise: true)

		let pointerStart = beziePath.currentPoint
		let y = cornerRadius * 0.5 + offset
		let x = point.x + cornerRadius
		let pointerEnd = CGPoint(x: x, y: y)
		addUpperRightPointerToBezierPath(beziePath, startPoint: pointerStart, endPoint: pointerEnd)

		point = beziePath.currentPoint
		point.y = CGRectGetHeight(bounds) - cornerRadius - offset
		beziePath.addLineToPoint(point)
		point.x -= cornerRadius
		beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: 0, endAngle: CGFloat(M_PI_2), clockwise: true)
        point = beziePath.currentPoint
        point.x = cornerRadius + offset
        beziePath.addLineToPoint(point)
        point.y -= cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: CGFloat(M_PI), clockwise: true)
        beziePath.closePath()
        return beziePath
    }

	private func addUpperRightPointerToBezierPath(bezierPath: UIBezierPath, startPoint: CGPoint, endPoint: CGPoint) {
		let aPointerSize = pointerSize
		let xDelta = endPoint.x - startPoint.x
		let farPoint = CGPoint(x: startPoint.x + aPointerSize.width, y: endPoint.y - aPointerSize.height)
		var controlPoint = CGPoint(x: startPoint.x + xDelta * 0.5, y: endPoint.y - aPointerSize.height * 0.95)
		bezierPath.addQuadCurveToPoint(farPoint, controlPoint: controlPoint)
		controlPoint = CGPoint(x: startPoint.x + xDelta * 1.2, y: endPoint.y - aPointerSize.height * 0.6)
		bezierPath.addQuadCurveToPoint(endPoint, controlPoint: controlPoint)
	}
    
    // MARK: - Draw Left Speech Bubble
    
    private func bezierPathForLeft() -> UIBezierPath {
        let aPointerSize = pointerSize
        let offset = lineWidth / 2.0
        let angle = RadiangsFromDegrees(125)
        let pointerOffset = PoinOnCircleWithRadius(cornerRadius, angle: angle, origin: CGPoint(x: cornerRadius, y: cornerRadius))
        let leftEdgeOffset = cornerRadius + aPointerSize.width - pointerOffset.x + offset
        
        let beziePath = UIBezierPath()
        var point = CGPoint(x: CGRectGetWidth(bounds) - cornerRadius - offset, y: cornerRadius + offset)
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(-M_PI_2), clockwise: false)
        point = beziePath.currentPoint
        point.x = leftEdgeOffset
        beziePath.addLineToPoint(point)
        point.y = cornerRadius + offset
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI), clockwise: false)
        point = beziePath.currentPoint
        point.y = CGRectGetHeight(bounds) - cornerRadius * 0.5 - offset
        beziePath.addLineToPoint(point)
        
        let pointerStart = point
        point.y -= cornerRadius * 0.5
        point.x += cornerRadius
        let pointerEnd = PoinOnCircleWithRadius(cornerRadius, angle: angle, origin: point)
        addLeftPointerToBezierPath(beziePath, startPoint: pointerStart, endPoint: pointerEnd)
        
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: angle, endAngle: CGFloat(M_PI_2), clockwise: false)
        point = beziePath.currentPoint
        point.x = CGRectGetWidth(bounds) - cornerRadius - offset
        beziePath.addLineToPoint(point)
        point.y -= cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: 0.0, clockwise: false)
        beziePath.closePath()
        return beziePath
    }
    
    private func addLeftPointerToBezierPath(bezierPath: UIBezierPath, startPoint: CGPoint, endPoint: CGPoint) {
        let aPointerSize = pointerSize
        let xDelta = endPoint.x - startPoint.x
        let farPoint = CGPoint(x: endPoint.x - aPointerSize.width, y: startPoint.y + aPointerSize.height)
        var controlPoint = CGPoint(x: endPoint.x - xDelta * 1.2, y: startPoint.y + aPointerSize.height * 0.6)
        bezierPath.addQuadCurveToPoint(farPoint, controlPoint: controlPoint)
        controlPoint = CGPoint(x: endPoint.x - xDelta * 0.5, y: startPoint.y + aPointerSize.height * 0.95)
        bezierPath.addQuadCurveToPoint(endPoint, controlPoint: controlPoint)
    }
}

func PoinOnCircleWithRadius(radius: CGFloat, angle: CGFloat, origin: CGPoint = CGPointZero) -> CGPoint {
    let x = origin.x + radius * cos(angle)
    let y = origin.y + radius * sin(angle)
    return CGPoint(x: x, y: y)
}

func RadiangsFromDegrees(degrees: Int) -> CGFloat {
    return CGFloat(degrees) * CGFloat(M_PI) / CGFloat(180)
}