//
//  APIManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

class APIManager {
    
    static let sharedInstance = APIManager()
    
    private struct Constants {
       static let BaseURL = NSURL(string: "www.google.com")!
    }
    
    let sessionManager = RCSessionManager(baseURL: Constants.BaseURL)
}
