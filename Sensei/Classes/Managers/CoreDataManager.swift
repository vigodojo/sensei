//
//  CoreDataManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient
import CoreData

class CoreDataManager {
    
    static let sharedInstance = CoreDataManager()
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last! 
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("SenseiModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Sensei.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption:NSNumber(bool: true),
                NSInferMappingModelAutomaticallyOption:NSNumber(bool: true)])
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "SENSEI_ERROR_DOMAIN", code: 666, userInfo: dict)
            NSLog("Unresolved error \(error), \(error!.userInfo)")
        } catch {
            fatalError()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                }
            }
        }
    }
    
    // MARK: - Creation
    
    func createObjectForEntityWithName(entityName: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.managedObjectContext!) 
    }
    
    func deleteManagedObject(object: NSManagedObject) {
        self.managedObjectContext!.deleteObject(object)
    }
    
    // MARK: - Fetching
    
    func fetchObjectsWithEntityName(entityName: String, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?) -> [NSManagedObject]? {
        let fetchRquest = NSFetchRequest(entityName: entityName)
        fetchRquest.sortDescriptors = sortDescriptors
        fetchRquest.predicate = predicate
        return (try? managedObjectContext!.executeFetchRequest(fetchRquest)) as? [NSManagedObject]
    }
    
    func fetchObjectsWithEntityName(entityName: String, sortDescriptors: [NSSortDescriptor]) -> [NSManagedObject]? {
        return fetchObjectsWithEntityName(entityName, sortDescriptors: sortDescriptors, predicate: nil)
    }
    
    // MARK: Merging
    
    func mergeJSONs(jsons: [JSONObject]?, entityMapping: EntityMapping) {
//        print("Started: \(NSDate().timeIntervalSince1970)")
        if let jsons = jsons where NSJSONSerialization.isValidJSONObject(jsons) {
            let newPrimaryValues = jsons.map { entityMapping.valueForProperty(entityMapping.primaryProperty, json: $0)! }
            let sortDescriptor = [NSSortDescriptor(key: entityMapping.primaryProperty, ascending: true)]
            
            if let fetchedItems = fetchObjectsWithEntityName(entityMapping.entityName, sortDescriptors: sortDescriptor) {
                for managedObject in fetchedItems {
                    if !(newPrimaryValues as NSArray).containsObject(managedObject.valueForKey(entityMapping.primaryProperty)!) {
                        self.managedObjectContext!.deleteObject(managedObject)
                    }
                }
                CoreDataManager.sharedInstance.saveContext()
                if let fetchedObjects = fetchObjectsWithEntityName(entityMapping.entityName, sortDescriptors: sortDescriptor) {
                    let oldPrimaryValues = fetchedObjects.map { $0.valueForKey(entityMapping.primaryProperty)! }
                    for json in jsons {
                        let jsonPrimaryKey = entityMapping.propertyMapping[entityMapping.primaryProperty]!
                        if let primaryValue = entityMapping.valueForProperty(jsonPrimaryKey, json: json) as? NSObject {
                            if !(oldPrimaryValues as NSArray).containsObject(primaryValue) {
                                createEntityObjectFromJSON(json, entityMapping: entityMapping)
                            } else {
                                let object = fetchedObjects.filter() { ($0.valueForKey(entityMapping.primaryProperty) as! NSObject).isEqual(primaryValue) }.first
                                if object != nil {
                                    updateEntityObject(object!, withJSON: json, entityMapping: entityMapping)
                                }
                            }
                        }
                    }
                    CoreDataManager.sharedInstance.saveContext()
                }
            }
        }
//        print("Ended: \(NSDate().timeIntervalSince1970)")
    }
    
    func updateInstructions(jsons: JSONObject?) {
        if let jsons = jsons where NSJSONSerialization.isValidJSONObject(jsons) {
            let result = NSMutableDictionary()
            if let visualizationInstructions = jsons["visualization"] as? NSArray {
                let visualizations = NSMutableDictionary()
                for json in visualizationInstructions {
                    let number = json["number"] as! NSInteger
                    let text = json["text"] as! String
                    
                    visualizations.setObject(text, forKey: "\(number)")
                }
                result["visualization"] = visualizations
            }
            if let affirmationInstructions = jsons["affirmation"] as? NSArray {
                let affirmations = NSMutableDictionary()
                for json in affirmationInstructions {
                    let number = json["number"] as! NSInteger
                    let text = json["text"] as! String
                    
                    affirmations.setObject(text, forKey: "\(number)")
                }
                result["affirmation"] = affirmations
            }
            
            let path = TutorialManager.pathForInstructions()
            let data = NSKeyedArchiver.archivedDataWithRootObject(result)
            NSKeyedArchiver.archiveRootObject(data, toFile: path)

            TutorialManager.sharedInstance.updateInstructions()
        }
    }
    
    func createEntityObjectFromJSON(json: JSONObject, entityMapping: EntityMapping) -> NSManagedObject {
        let object = createObjectForEntityWithName(entityMapping.entityName)
        for (objectKey, _) in entityMapping.propertyMapping {
            object.setValue(entityMapping.valueForProperty(objectKey, json: json), forKey: objectKey)
        }
        return object
    }
    
    func updateEntityObject(object: NSManagedObject, withJSON json: JSONObject, entityMapping: EntityMapping) -> Bool {
        var hasChanges = false
        for (objectKey, _) in entityMapping.propertyMapping {
            if let jsonValue = entityMapping.valueForProperty(objectKey, json: json) as? NSObject {
                if (object.valueForKeyPath(objectKey) as? NSObject) != jsonValue {
                    object.setValue(jsonValue, forKeyPath: objectKey)
                    hasChanges = true
                }
            }
        }
        return hasChanges
    }
}

// MARK: - MAPPING

protocol JSONValueTransformerProtocol
{
    func valueFromString(string: String) -> AnyObject?
    func stringFromValue(value: AnyObject) -> String?
}

struct EntityMapping {
    
    let entityName: String
    let propertyMapping: [String: String]
    let primaryProperty: String
    var valueTransformers: [String: JSONValueTransformerProtocol]
    
    func jsonStringForProperty(property: String, object: NSManagedObject) -> String? {
        let value: AnyObject? = object.valueForKey(property)
        if let transformerClass = valueTransformers[property] {
            return transformerClass.stringFromValue(value!)
        }
        return value as? String
    }
    
    func valueForProperty(property: String, json: [NSObject: AnyObject]) -> AnyObject? {
        let jsonValue: AnyObject? = (json as NSDictionary).valueForKeyPath(propertyMapping[property]!)
        if let transformerClass = valueTransformers[property], jsonValue = jsonValue as? String {
            return transformerClass.valueFromString(jsonValue)
        }
        return jsonValue
    }
}
