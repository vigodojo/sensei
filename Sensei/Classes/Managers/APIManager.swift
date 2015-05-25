//
//  APIManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

class APIManager: NSObject {
    
    static let sharedInstance = APIManager()
    static let BaseURL = NSURL(string: "http://134.249.164.53:8831")!
    
    private struct APIPath {
        static let Login = "/user/signIn"
    }
    
    lazy var sessionManager: RCSessionManager = { [unowned self] in
        let manager = RCSessionManager(baseURL: APIManager.BaseURL)
        manager.delegate = self
        return manager
    }()
    
    func loginWithDeviceId(deveiceId: String, timeZone: Int, handler: ((error: NSError?) -> Void)?) {
        sessionManager.performRequestWithBuilderBlock({ (requestBuilder) -> Void in
            requestBuilder.path = APIPath.Login
            requestBuilder.requestMethod = RCRequestMethod.POST
            requestBuilder.object = ["deviceId": deveiceId, "timeZone": NSNumber(integer: timeZone)]
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
}

extension APIManager: RCSessionManagerDelegate {
    
    func sessionManager(sessionManager: RCSessionManager!, didReceivedResponse response: RCResponse!) {
        //
    }
}