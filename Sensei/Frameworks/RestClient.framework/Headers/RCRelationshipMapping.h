//
//  RCRelationshipMapping.h
//  RestClient
//
//  Created by Sauron Black on 3/29/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCObjectMapping;

@interface RCRelationshipMapping : NSObject

@property (strong, nonatomic) NSString *fromKeyPath;
@property (strong, nonatomic) NSString *toKeyPath;
@property (strong, nonatomic) RCObjectMapping *objectMapping;

- (instancetype)initWithFromKeyPath:(NSString *)fromKeyPath toKeyPath:(NSString *)toKeyPath objectMapping:(RCObjectMapping *)objectMapping;

@end
