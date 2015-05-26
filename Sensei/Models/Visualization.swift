//
//  Visualization.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData

class Visualization: UserMessage {
    
    static let EntityName = "Visualization"

    @NSManaged private var pictureData: NSData?
    
    var picture: UIImage? {
        get {
            if let pictureData = pictureData {
                return UIImage(data: pictureData)
            }
            return nil
        }
        set {
            if let image = newValue {
                pictureData = UIImagePNGRepresentation(image)
            } else {
                pictureData = nil
            }
        }
    }
    
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
}
