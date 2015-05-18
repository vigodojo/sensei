//
//  RCRequestBuilder.h
//  RestClient
//
//  Created by Sauron Black on 3/28/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCConstants.h"

@class RCRequestDescriptor;

@interface RCRequestBuilder : NSObject

@property (strong, nonatomic) NSURL *baseURL;
@property (strong, nonatomic) NSString *path;
@property (assign, nonatomic) RCRequestMethod requestMethod;
@property (assign, nonatomic) RCContentType contentType;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSDictionary *parameters;
@property (strong, nonatomic) RCRequestDescriptor *requestDescriptor;

- (void)addHTTPHeaderFields:(NSDictionary *)headerFields;
- (NSURLRequest *)buildRequest;

@end

@interface NSURLRequest (RCRequestBuilder)

+ (instancetype)requestWithBuilderBlock:(RCRequestBuilderBlock)builderBlock;

@end
