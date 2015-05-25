//
//  AppDelegate.swift
//  Sensei
//
//  Created by Sauron Black on 5/6/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }
    
    func testCoreDataCreation() {
        Affirmation.createAffirmationNumber(NSNumber(integer: 1), text: "Black Metal Isk Krieg", receiveTime: ReceiveTime.Morning)
        Visualization.createVisualizationWithNumber(NSNumber(integer: 1), text: "Trash Til Death", receiveTime: ReceiveTime.Evening, picture: UIImage(named: "VigoSensei")!)
        Affirmation.createAffirmationNumber(NSNumber(integer: 2), text: "Schwarzalbenheim", receiveTime: ReceiveTime.AnyTime)
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func testCoreDataFetch() {
        let visualizations = Visualization.visualizations
        println("Visualizations = \(visualizations)")
        println()
        let visualization = Visualization.visualizationWithNumber(NSNumber(integer: 1))
        println("\(visualization)")
        let image = visualization!.picture!
        println()
        let affirmations = Affirmation.affirmations
        println("Affirmations = \(affirmations)")
    }
}

