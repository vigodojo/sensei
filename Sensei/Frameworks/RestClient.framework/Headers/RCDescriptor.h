//
//  RCDescriptor.h
//  RestClient
//
//  Created by Sauron Black on 3/29/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCObjectMapping;

@interface RCDescriptor : NSObject

@property (strong, nonatomic) RCObjectMapping *objectMapping;
@property (strong, nonatomic) NSString *pathPattern;
@property (strong, nonatomic) NSString *rootKeyPath;

- (instancetype)initWithObjectMapping:(RCObjectMapping *)objectMapping pathPattern:(NSString *)pathPattern rootKeyPath:(NSString *)rootKeyPath;
- (instancetype)initWithObjectMapping:(RCObjectMapping *)objectMapping pathPattern:(NSString *)pathPattern;

@end
