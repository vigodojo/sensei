//
//  OfflineManager.swift
//  Sensei
//
//  Created by Sergey Sheba on 2/16/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class OfflineManager {
    
    private struct UserDefaultsKeys {
        static let DeletedAffirmations = "DeletedAffirmations"
        static let DeletedVisualizations = "DeletedVisualizations"
    }
    
    static let sharedManager = OfflineManager()
    
    // MARK: Save/Retrieve NSUserDefaults
    
    func arrayFromDefaults(key: String) -> [NSNumber] {
        if let array = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [NSNumber] {
            return array
        } else {
            return[NSNumber]()
        }
    }
    
    func saveArrayToDefaults(array: Array<NSNumber>, key: String) {
        NSUserDefaults.standardUserDefaults().setObject(array, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    // MARK: Affirmations
    
    func deletedAffirmations() -> [NSNumber] {
        return arrayFromDefaults(UserDefaultsKeys.DeletedAffirmations)
    }
    
    func resetDeletedAffirmations() {
        saveArrayToDefaults([NSNumber](), key: UserDefaultsKeys.DeletedAffirmations)
    }
    
    func affirmationDeleted(number: NSNumber) {
        if isAffirmationDeleted(number) {
            return
        }
        var deletedAffirmationsArray = deletedAffirmations()
        deletedAffirmationsArray.append(number)
        saveArrayToDefaults(deletedAffirmationsArray, key: UserDefaultsKeys.DeletedAffirmations)
    }
    
    func isAffirmationDeleted(number: NSNumber) -> Bool {
        let deletedAffirmationsArray = deletedAffirmations()
        for affNumber in deletedAffirmationsArray {
            if affNumber.integerValue == number.integerValue {
                return true
            }
        }
        return false
    }
    
    func deleteAffirmationFromDeleted(number: NSNumber) {
        if !isAffirmationDeleted(number) {
            return
        }
        var deletedAffirmationsArray = deletedAffirmations()
        for index in 0...deletedAffirmationsArray.count - 1 {
            if number.integerValue == deletedAffirmationsArray[index].integerValue {
                deletedAffirmationsArray.removeAtIndex(index)
                saveArrayToDefaults(deletedAffirmationsArray, key: UserDefaultsKeys.DeletedAffirmations)
                return
            }
        }
    }
    
    //MARK: Visualizations
    
    func deletedVisualizations() -> [NSNumber] {
        return arrayFromDefaults(UserDefaultsKeys.DeletedVisualizations)
    }
    
    func resetDeletedVisualizations() {
        saveArrayToDefaults([NSNumber](), key: UserDefaultsKeys.DeletedVisualizations)
    }
    
    func visualizationDeleted(number: NSNumber) {
        if isVisualizationDeleted(number) {
            return
        }
        var deletedVisualizationsArray = deletedVisualizations()
        deletedVisualizationsArray.append(number)
        saveArrayToDefaults(deletedVisualizationsArray, key: UserDefaultsKeys.DeletedVisualizations)
    }
    
    func isVisualizationDeleted(number: NSNumber) -> Bool {
        let deletedVisualizationsArray = deletedVisualizations()
        for affNumber in deletedVisualizationsArray {
            if affNumber.integerValue == number.integerValue {
                return true
            }
        }
        return false
    }
    
    func deleteVisualizationFromDeleted(number: NSNumber) {
        if !isVisualizationDeleted(number) {
            return
        }
        var deletedVisualizationsArray = deletedVisualizations()
        for index in 0...deletedVisualizationsArray.count - 1 {
            if number.integerValue == deletedVisualizationsArray[index].integerValue {
                deletedVisualizationsArray.removeAtIndex(index)
                saveArrayToDefaults(deletedVisualizationsArray, key: UserDefaultsKeys.DeletedVisualizations)
                return
            }
        }
    }
    
    //MARK: Synch 
    
    func synchronizeWithServer() {
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
        synchAffirmations()
        synchVisualizations()
    }
    
    private func synchVisualizations() {
        for visualization in Visualization.offlineVisualizations() {
            visualization.updatedOffline = NSNumber(bool: false)
            CoreDataManager.sharedInstance.saveContext()
            print("updating Vis with number \(visualization.number)")
            APIManager.sharedInstance.saveVisualization(visualization, handler: { (error) -> Void in
                if error == nil {
                    print("Vis number \(visualization.number) was updated")
                } else {
                    print("a problem occured while updated Vis number \(visualization.number)")
                }
            })
        }
        for number in OfflineManager.sharedManager.deletedVisualizations() {
            print("deleting Vis with number \(number)")
            APIManager.sharedInstance.deleteVisualizationWithNumber(number, handler: { (error) -> Void in
                if error == nil {
                    print("Vis number \(number) was deleted")
                } else {
                    print("a problem occured while deleting Vis number \(number)")
                }
            })
        }
        OfflineManager.sharedManager.resetDeletedVisualizations()
    }
    
    private func synchAffirmations() {
        for affirmation in Affirmation.offlineAffirmations() {
            affirmation.updatedOffline = NSNumber(bool: false)
            CoreDataManager.sharedInstance.saveContext()
            print("updating Aff with number \(affirmation.number)")
            APIManager.sharedInstance.saveAffirmation(affirmation, handler: { (error) -> Void in
                if error == nil {
                    print("Aff number \(affirmation.number) was updated")
                } else {
                    print("a problem occured while updated Aff number \(affirmation.number)")
                }
            })
        }
        for number in OfflineManager.sharedManager.deletedAffirmations() {
            print("deleting Aff with number \(number)")
            APIManager.sharedInstance.deleteAffirmationWithNumber(number, handler: { (error) -> Void in
                if error == nil {
                    print("Aff number \(number) was deleted")
                } else {
                    print("a problem occured while deleting Aff number \(number)")
                }
            })
        }
        OfflineManager.sharedManager.resetDeletedAffirmations()
    }
}
