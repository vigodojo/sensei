//
//  CoreDataManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static let sharedInstance = CoreDataManager()
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last as! NSURL
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
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "SENSEI_ERROR_DOMAIN", code: 666, userInfo: dict)
            NSLog("Unresolved error \(error), \(error!.userInfo)")
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
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
            }
        }
    }
    
    // MARK: - Fetching
    
    func fetchObjectsWithEntityName(entityName: String, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?) -> [AnyObject]? {
        let fetchRquest = NSFetchRequest(entityName: entityName)
        fetchRquest.sortDescriptors = sortDescriptors
        fetchRquest.predicate = predicate
        return managedObjectContext!.executeFetchRequest(fetchRquest, error: nil)
    }
    
    func fetchObjectsWithEntityName(entityName: String, sortDescriptors: [NSSortDescriptor]) -> [AnyObject]? {
        return fetchObjectsWithEntityName(entityName, sortDescriptors: sortDescriptors, predicate: nil)
    }
}