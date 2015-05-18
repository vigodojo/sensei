//
//  RCResponseDescriptor.h
//  RestClient
//
//  Created by Sauron Black on 3/29/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import "RCDescriptor.h"
#import "RCConstants.h"

@class RCResponseDescriptor;

typedef void(^RCResponseDescriptorConfigurationBlock)(RCResponseDescriptor *responseDescriptor);

@interface RCResponseDescriptor : RCDescriptor

@property (assign, nonatomic) RCRequestMethod requestMethod;
@property (assign, nonatomic) RCStatusCodeClass statusCodeClass;

- (instancetype)initWithBlock:(RCResponseDescriptorConfigurationBlock)block;

- (id)mappedObjectWithData:(NSData *)data;

@end

