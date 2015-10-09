//
//  Visualization.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData
import RestClient
import AVFoundation

class Visualization: UserMessage {
    
    static let EntityName = "Visualization"
    static let MinFontSize: CGFloat = 22.0

    @NSManaged private var pictureData: NSData?
    @NSManaged var scaledFontSize: NSNumber
    
    var picture: UIImage? {
        get {
            if let pictureData = pictureData {
                return UIImage(data: pictureData)
            }
            return nil
        }
        set {
            if let image = newValue {
                pictureData = UIImageJPEGRepresentation(image, 1.0)
            } else {
                pictureData = nil
            }
        }
    }
    
    var imageId = "666"
    
    // MARK: Public
    
    class func scaledFontSizeForFontSize(fontSize: CGFloat, imageSize: CGSize, insideRect: CGRect) -> CGFloat {
        let imageRect = AVMakeRectWithAspectRatioInsideRect(imageSize, insideRect)
        return CGFloat(Int(imageSize.height * fontSize / CGRectGetHeight(imageRect)))
    }
    
    class func outlinedTextAttributesWithMinFontSize() -> [String: AnyObject] {
        return outlinedTextAttributesWithFontSize(MinFontSize)
    }
    
    class func outlinedTextAttributesWithFontSize(fontSize: CGFloat) -> [String: AnyObject] {
        return outlinedTextAttributesWithFontSize(fontSize, color: UIColor.whiteColor())
    }
    
    class func outlinedTextAttributesWithFontSize(fontSize: CGFloat, color: UIColor) -> [String: AnyObject] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        
        return [NSStrokeColorAttributeName: UIColor.blackColor(),
            NSForegroundColorAttributeName: color,
            NSStrokeWidthAttributeName: NSNumber(double:-4.0),
            NSFontAttributeName: UIFont.helveticaNeueBlackOfSize(fontSize),
            NSParagraphStyleAttributeName: paragraphStyle]
    }
    
    class func findFontSizeForText(text: String, textContainerSize: CGSize, maxFontSize: CGFloat) -> CGFloat? {
        var fontSize = maxFontSize
        if fontSize > Visualization.MinFontSize {
			var width = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size().width
            while width >= textContainerSize.width && fontSize > Visualization.MinFontSize {
                fontSize--
                width = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(fontSize)).size().width
            }
        }
        if fontSize == Visualization.MinFontSize {
            let size = CGSizeMake(textContainerSize.width, CGFloat.max)
            let options: NSStringDrawingOptions = ([NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading])
            let attributes = Visualization.outlinedTextAttributesWithMinFontSize()
            let height = CGRectGetHeight((text as NSString).boundingRectWithSize(size, options: options, attributes: attributes, context: nil))
            return height <= textContainerSize.height ? fontSize: nil
        }
        return fontSize
    }
    
    // MARK: CoreData
    
    class func createVisualizationWithNumber(number: NSNumber, text: String, receiveTime: ReceiveTime, picture: UIImage) -> Visualization {
        let newVisualization = NSEntityDescription.insertNewObjectForEntityForName(Visualization.EntityName, inManagedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!) as! Visualization
        newVisualization.number = number
        newVisualization.text = text
        newVisualization.receiveTime = receiveTime
        newVisualization.picture = picture
        return newVisualization
    }
    
    class func visualizationWithNumber(number: NSNumber) -> Visualization? {
        let sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let predicate = NSPredicate(format: "number == %@", number)
        let objects = CoreDataManager.sharedInstance.fetchObjectsWithEntityName(Visualization.EntityName, sortDescriptors: sortDescriptors, predicate: predicate)
        return objects?.first as? Visualization
    }
    
    class var visualizations: [Visualization] {
        let sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        if let result = CoreDataManager.sharedInstance.fetchObjectsWithEntityName(Visualization.EntityName, sortDescriptors: sortDescriptors) as? [Visualization] {
            return result
        } else {
            return [Visualization]()
        }
    }
    
    // MARK: Mapping
    
    override class var objectMapping: RCObjectMapping {
        let mapping = super.objectMapping
        mapping.addPropertyMappingFromArray(["imageId"])
        return mapping
    }
    
    class var requestDescriptor: RCRequestDescriptor {
        return RCRequestDescriptor(objectMapping: Visualization.objectMapping.inversMapping(), pathPattern: APIManager.APIPath.VisualizationPathPattern)
    }
}
