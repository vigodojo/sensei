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
        if !deletedAffirmationsArray.contains(number) {
            deletedAffirmationsArray.append(number)
            saveArrayToDefaults(deletedAffirmationsArray, key: UserDefaultsKeys.DeletedAffirmations)
        }
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
        if !deletedVisualizationsArray.contains(number) {
            deletedVisualizationsArray.append(number)
            saveArrayToDefaults(deletedVisualizationsArray, key: UserDefaultsKeys.DeletedVisualizations)
        }
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
        if TutorialManager.sharedInstance.completed {
            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: { (error) in
                guard let _ = error else {
                    print("settings updated")
                    self.synchAffirmations()
                    self.synchVisualizations()
                    return
                }
            })
        }
    }
    
    private func synchVisualizations() {
        let visualizations = Visualization.offlineVisualizations()
        print("\(visualizations.count) updated visualizations")
        self.deleteVisualization(OfflineManager.sharedManager.deletedVisualizations(), counter: 0, completion: { (finished) -> Void in
            OfflineManager.sharedManager.resetDeletedVisualizations()
            self.updateVisualization(visualizations, counter: 0) { () -> Void in
            }
        })
    }

    private func deleteVisualization(visualizations: Array<NSNumber>, counter: Int,  completion:((finished: Bool) -> Void)?) {
        print("\(visualizations.count) deleted visualizations")

        var counter = counter
        if counter >= visualizations.count {
            if let completion = completion {
                completion(finished: true)
            }
            return
        }
        APIManager.sharedInstance.deleteVisualizationWithNumber(visualizations[counter]) { [unowned self] (error) -> Void in
            if error == nil {
                print("DELETED VISUALIZATION \(visualizations[counter])")
                counter += 1
            } else {
                print("ERROR DELETING VISUALIZATION \(visualizations[counter])")
            }
            self.deleteVisualization(visualizations, counter: counter, completion: completion)
        }
    }
    
    
    private func updateVisualization(visualizations: Array<Visualization>, counter: Int,  completion:(() -> Void)?) {
        var counter = counter
        if counter >= visualizations.count {
            completion
            return
        }
                
        visualizations[counter].updatedOffline = NSNumber(bool: false)
        CoreDataManager.sharedInstance.saveContext()
        
        APIManager.sharedInstance.saveVisualization(visualizations[counter], handler: { [unowned self] (error) -> Void in
            if error == nil {
                print("UPDATED VISUALIZATION \(visualizations[counter].number)")
                counter += 1
            } else {
                print("ERROR UPDATING VISUALIZATION \(visualizations[counter].number)")
            }
            self.updateVisualization(visualizations, counter: counter, completion: completion)
        })
    }
    
    private func synchAffirmations() {
        let affirmations = Affirmation.offlineAffirmations()
        print("\(affirmations.count) updated affirmations")

        self.deleteAffirmation(OfflineManager.sharedManager.deletedAffirmations(), counter: 0, completion: { (finished) -> Void in
            OfflineManager.sharedManager.resetDeletedAffirmations()
            self.updateAffirmation(affirmations, counter: 0) { () -> Void in
                
            }
        })
    }
    
    private func deleteAffirmation(affirmations: Array<NSNumber>, counter: Int,  completion:((finished: Bool) -> Void)?) {
        print("\(affirmations.count) deleted affirmations")

        var counter = counter
        if counter >= affirmations.count {
            if let completion = completion {
                completion(finished: true)
            }
            return
        }
        APIManager.sharedInstance.deleteAffirmationWithNumber(affirmations[counter]) { [unowned self] (error) -> Void in
            if error == nil {
                print("DELETED AFFIRMATION \(affirmations[counter])")
                counter += 1
            } else {
                print("ERROR DELETING AFFIRMATION \(affirmations[counter])")
            }
            self.deleteAffirmation(affirmations, counter: counter, completion: completion)
        }
    }
    
    private func updateAffirmation(affirmations: Array<Affirmation>, counter: Int,  completion:(() -> Void)?) {
        var counter = counter
        if counter >= affirmations.count {
            completion
            return
        }
        affirmations[counter].updatedOffline = NSNumber(bool: false)
        CoreDataManager.sharedInstance.saveContext()
        
        APIManager.sharedInstance.saveAffirmation(affirmations[counter], handler: { [unowned self] (error) -> Void in
            if error == nil {
                print("UPDATED AFFIRMATION \(affirmations[counter].number)")
                counter += 1
            } else {
                print("ERROR UPDATING AFFIRMATION \(affirmations[counter].number)")
            }
            self.updateAffirmation(affirmations, counter: counter, completion: completion)
        })
    }
}