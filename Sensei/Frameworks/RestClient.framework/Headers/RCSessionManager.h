//
//  RCSessionManager.h
//  RestClient
//
//  Created by Sauron Black on 3/28/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCConstants.h"

@class RCResponse;
@class RCRequestDescriptor, RCResponseDescriptor;

@protocol RCSessionManagerDelegate;

@interface RCSessionManager : NSObject

@property (strong, readonly, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURL *baseURL;
@property (assign, nonatomic) RCContentType defaultContentType;
@property (weak, nonatomic) id<RCSessionManagerDelegate> delegate;

- (instancetype)initWithBaseURL:(NSURL *)url;

- (void)setValue:(id)value forDefaultHTTTPHeaderField:(NSString *)key;
- (void)removeValueForDefaultHTTTPHeaderField:(NSString *)key;
- (void)addRequestDescriptor:(RCRequestDescriptor *)requestDescriptor;
- (void)addResponseDescriptor:(RCResponseDescriptor *)responseDescriptor;
- (void)performRequest:(NSURLRequest *)request completion:(RCRequestCompletion)completion;
- (void)performRequestWithBuilderBlock:(RCRequestBuilderBlock)builderBlock completion:(RCRequestCompletion)completion;

@end

@protocol RCSessionManagerDelegate <NSObject>

@optional
- (void)sessionManager:(RCSessionManager *)sessionManager didReceivedResponse:(RCResponse *)response;

@end
