//
//  Message.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

protocol Message: NSObjectProtocol {
    
    var text: String { get set }
}

class Lesson: NSObject, Message {
    
    var lessonId = ""
    var text = ""
    var date = NSDate()
    
    override init() {
        super.init()
    }
    
    init(text: String) {
        self.text = text
    }
    
    class var objectMapping: RCObjectMapping {
        return RCObjectMapping(objectClass: Lesson.self, mappingArray: ["lessonId", "text", "date"])
    }
    
    class var responseDescriptor: RCResponseDescriptor {
        return RCResponseDescriptor(objectMapping: Lesson.objectMapping, pathPattern: APIManager.APIPath.LessonsHistory)
    }
}