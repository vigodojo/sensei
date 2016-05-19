//
//  PlanViewController.swift
//  Sensei
//
//  Created by Sergey Sheba on 28.04.16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class PlanViewController: UIViewController {

    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet weak var sleepTimeLabel: UILabel!
    @IBOutlet weak var sleepTimeWeekendLabel: UILabel!
    @IBOutlet weak var weightStatusLabel: UILabel!
    @IBOutlet weak var upgradedLabel: UILabel!

    var dataSource = [[String: AnyObject]]()
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl.addTarget(self, action: #selector(PlanViewController.refresh(_:)), forControlEvents: .ValueChanged)
        tableVIew.addSubview(refreshControl)
        reloadPlan()
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        reloadPlan()
    }
    
    @IBAction func close(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func reloadPlan() {
        if let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as? String {
            APIManager.sharedInstance.userPlanWithCompletion(idfa) { [weak self](response, error) in
                print("response: \(response)")
                
                if let response = response, let dataSource = response["plan"] as? [[String:AnyObject]] {
                    let user = response["user"]!
                    let settings = user["settings"]!
                    let sleepTime = settings!["sleepTime"]!
                    let sleepTimeWeekEnd = settings!["sleepTimeWeekEnd"]!
                    let isUpgraded = user["isUpgraded"] as! Bool
                    
                    if let weightStatus = user["weightStatus"] as? String {
                        self?.weightStatusLabel.text = "WeightStatus: \(weightStatus)"
                    }
                    self?.upgradedLabel.text = "Upgraded: \(isUpgraded)"
                    self?.sleepTimeLabel.text = "SleepTime: \(sleepTime!["start"] as! String) - \(sleepTime!["end"] as! String)"
                    self?.sleepTimeWeekendLabel.text = "SleepTimeWeekEnd: \(sleepTimeWeekEnd!["start"] as! String) - \(sleepTimeWeekEnd!["end"] as! String)"
                    
                    
                    self?.dataSource = dataSource
                } else {
                    self?.dataSource = [[String: AnyObject]]()
                }
                if let error = error {
                    dispatch_async(dispatch_get_main_queue(), { 
                        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
                    })
                }
                self?.tableVIew.reloadData()
                self?.refreshControl.endRefreshing()
            }
        }
    }
}

extension PlanViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
        cell.data = dataSource[indexPath.row]
        return cell
    }
}