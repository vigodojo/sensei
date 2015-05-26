//
//  Affirmation.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData

class Affirmation: UserMessage {
    
    static let EntityName = "Affirmation"
    
    class func createAffirmationNumber(number: NSNumber, text: String, receiveTime: ReceiveTime) -> Affirmation {
        let newAffirmation = NSEntityDescription.insertNewObjectForEntityForName(Affirmation.EntityName, inManagedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!) as! Affirmation
        newAffirmation.number = number
        newAffirmation.text = text
        newAffirmation.receiveTime = receiveTime
        return newAffirmation
    }
    
    class func affirmationWithNumber(number: NSNumber) -> Affirmation? {
        let sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let predicate = NSPredicate(format: "number == %@", number)
        let objects = CoreDataManager.sharedInstance.fetchObjectsWithEntityName(Affirmation.EntityName, sortDescriptors: sortDescriptors, predicate: predicate)
        return objects?.first as? Affirmation
    }
    
    func saveAffirmationWithNumber(number: NSNumber, text: String, receiveTime: ReceiveTime) {
        if let affirmaton = Affirmation.affirmationWithNumber(number) {
            affirmaton.text = text
            affirmaton.receiveTime = receiveTime
        } else {
            Affirmation.createAffirmationNumber(number, text: text, receiveTime: receiveTime)
        }
        CoreDataManager.sharedInstance.saveContext()
    }
    
    class var affirmations: [Affirmation] {
        let sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        if let result = CoreDataManager.sharedInstance.fetchObjectsWithEntityName(Affirmation.EntityName, sortDescriptors: sortDescriptors) as? [Affirmation] {
            return result
        } else {
            return [Affirmation]()
        }
    }
}
