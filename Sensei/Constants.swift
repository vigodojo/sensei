//
//  Constants.swift
//  Sensei
//
//  Created by Sauron Black on 6/30/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

let AnimationDuration = 0.25
let TutorialStepTimeinteval = UInt64(2)
//let LinkToAppOnAppStore = NSURL(string: "https://itunes.apple.com/us/app/gpforum/id1207803579")!
let LinkToAppOnAppStore = NSURL(string: "https://itunes.apple.com/us/app/vigo-sensei/id1174329284")!

let LinkToAffirmation = NSURL(string: "AffirmationUrl")!
let LinkToVisualization = NSURL(string: "VizualizationUrl")!

enum ScreenName: String {
    case Sensei = "SenseiScreen"
    case More = "MoreScreen"
    case Affirmation = "AffirmationScreen"
    case Visualisation = "VisualisationScreen"
}

enum ActionName: String {
    case ScrollToTop = "ScrollToTop"
    case ScrollToBottom = "ScrollToBottom"
    case SwitchTab = "SwitchTab"
}
