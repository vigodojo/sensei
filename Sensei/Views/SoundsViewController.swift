//
//  SoundsViewController.swift
//  Sensei
//
//  Created by Sergey Sheba on 05.05.16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit
import AVFoundation

class SoundsViewController: UIViewController {

    private var dataSource = [NSURL]()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        getSounds()
    }
    
    private var selectedSound: String?
    
    private func getSounds() {
        let fileManager = NSFileManager()
        let directoryURL = NSURL(string: "/System/Library/Audio/UISounds")
        let keys = [NSURLIsDirectoryKey]
        
        let enumerator = fileManager.enumeratorAtURL(directoryURL!, includingPropertiesForKeys: keys, options: NSDirectoryEnumerationOptions(rawValue: 0)) { (url, error) -> Bool in
            return true
        }
        
        for url in enumerator! {
            do {
                var resource: AnyObject?
                
                try (url as! NSURL).getResourceValue(&resource, forKey: NSURLIsDirectoryKey)
                
                if let number = resource as? NSNumber {
                    if number == false {
                        dataSource.append(url as! NSURL)
                    }
                }
            } catch {
                
            }
        }
        tableView.reloadData()
    }
    
    @IBAction func saveSound(sender: AnyObject) {
        if let newSelectedSound = self.selectedSound, let currentSound = NSUserDefaults.standardUserDefaults().stringForKey("SoundURL") where newSelectedSound != currentSound {
            NSUserDefaults.standardUserDefaults().setObject(newSelectedSound, forKey: "SoundURL")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func closeAction(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension SoundsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SoundCell") as! SoundCell
        cell.titleLabel.text = "\(indexPath.row+1): \(dataSource[indexPath.row].lastPathComponent!)"
        return cell
    }
}

extension SoundsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedSound = dataSource[indexPath.row].absoluteString
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(dataSource[indexPath.row], &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}
