//
//  RCResponse.h
//  RestClient
//
//  Created by Sauron Black on 3/29/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCResponse : NSObject

@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSURLRequest *request;
@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSError *error;
@property (readonly, nonatomic) NSInteger statusCode;
@property (readonly, nonatomic, getter=isSuccessful) BOOL successful;

@end
