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
    
    static var OutlinedTextAttributes: [String: AnyObject] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        
        return [NSStrokeColorAttributeName: UIColor.whiteColor(),
            NSForegroundColorAttributeName: UIColor.blackColor(),
            NSStrokeWidthAttributeName: NSNumber(double:-6.0),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 13.0)!,
            NSParagraphStyleAttributeName: paragraphStyle]
    }()

    @NSManaged private dynamic var pictureData: NSData?
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
    
    class func scaledFontSizeForImageWithSize(imageSize: CGSize, text: String, insideRect: CGRect) -> CGFloat {
        var attributes = Visualization.OutlinedTextAttributes
        let imageRect = AVMakeRectWithAspectRatioInsideRect(imageSize, insideRect)
        let font = (attributes[NSFontAttributeName] as! UIFont)
        return round(imageSize.height * font.pointSize / CGRectGetHeight(imageRect))
    }
    
    class func attributesForFontWithSize(fontSize: CGFloat) -> [NSObject: AnyObject] {
        let font = (Visualization.OutlinedTextAttributes[NSFontAttributeName] as! UIFont)
        var attributes = Visualization.OutlinedTextAttributes
        attributes[NSFontAttributeName] = UIFont(name: font.fontName, size: fontSize)
        return attributes
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
