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
        let visualizations = Visualization.offlineVisualizations()
        updateVisualization(visualizations, counter: 0) { [unowned self] () -> Void in
            self.deleteVisualization(OfflineManager.sharedManager.deletedVisualizations(), counter: 0, completion: { () -> Void in
                OfflineManager.sharedManager.resetDeletedVisualizations()
            })
        }
    }

    private func deleteVisualization(visualizations: Array<NSNumber>, var counter: Int,  completion:(() -> Void)?) {
        if counter >= visualizations.count {
            completion
            return
        }
        APIManager.sharedInstance.deleteVisualizationWithNumber(visualizations[counter]) { [unowned self] (error) -> Void in
            if error == nil {
                counter++
            }
            self.deleteVisualization(visualizations, counter: counter, completion: completion)
        }
    }
    
    private func updateVisualization(visualizations: Array<Visualization>, var counter: Int,  completion:(() -> Void)?) {
        if counter >= visualizations.count {
            completion
            return
        }
        visualizations[counter].updatedOffline = NSNumber(bool: false)
        CoreDataManager.sharedInstance.saveContext()
        
        APIManager.sharedInstance.saveVisualization(visualizations[counter], handler: { [unowned self] (error) -> Void in
            if error == nil {
                counter++
            }
            self.updateVisualization(visualizations, counter: counter, completion: completion)
        })
    }
    
    private func synchAffirmations() {
        let affirmations = Affirmation.offlineAffirmations()
        
        updateAffirmation(affirmations, counter: 0) { [unowned self] () -> Void in
            self.deleteVisualization(OfflineManager.sharedManager.deletedVisualizations(), counter: 0, completion: { () -> Void in
                OfflineManager.sharedManager.resetDeletedAffirmations()
            })
        }
    }
    
    private func deleteAffirmation(affirmations: Array<NSNumber>, var counter: Int,  completion:(() -> Void)?) {
        if counter >= affirmations.count {
            completion
            return
        }
        APIManager.sharedInstance.deleteAffirmationWithNumber(affirmations[counter]) { [unowned self] (error) -> Void in
            if error == nil {
                counter++
            }
            self.deleteAffirmation(affirmations, counter: counter, completion: completion)
        }
    }
    
    private func updateAffirmation(affirmations: Array<Affirmation>, var counter: Int,  completion:(() -> Void)?) {
        if counter >= affirmations.count {
            completion
            return
        }
        affirmations[counter].updatedOffline = NSNumber(bool: false)
        CoreDataManager.sharedInstance.saveContext()
        
        APIManager.sharedInstance.saveAffirmation(affirmations[counter], handler: { [unowned self] (error) -> Void in
            if error == nil {
                counter++
            }
            self.updateAffirmation(affirmations, counter: counter, completion: completion)
        })
    }
}