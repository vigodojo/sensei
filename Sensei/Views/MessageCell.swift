//
//  MessageCell.swift
//  Sensei
//
//  Created by Sergey Sheba on 28.04.16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dayTimeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var data: [String: AnyObject]? {
        didSet {
            if let data = data {
                
                if let messageTime = data["messageTime"] as? String {
                    let comps = messageTime.componentsSeparatedByString(":")
                    dateLabel.text = String(format: "Time: %02ld:%02ld +0000 GMT", Int(comps.first!)!, Int(comps.last!)!)
                }
                
                if let messageType = data["messageType"] as? String {
                    if messageType == "A" {
                        typeLabel.text = "Affirmation"
                    }
                    if messageType == "V" {
                        typeLabel.text = "Visualization"
                    }
                    if messageType == "L" {
                        typeLabel.text = "Lesson: \(data["messageTone"]!)"
                    }
                    if messageType == "G" {
                        typeLabel.text = "Global push"
                    }
                }
                
                let receiveTime = ReceiveTime(rawValue: data["time"] as! String)
                dayTimeLabel.text = receiveTime?.description
                
                print(data)
            }
        }
    }
}
