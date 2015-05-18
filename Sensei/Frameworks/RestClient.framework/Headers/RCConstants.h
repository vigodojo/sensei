//
//  RCConstants.h
//  RestClient
//
//  Created by Sauron Black on 3/28/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCRequestBuilder, RCResponse;

typedef void(^RCRequestBuilderBlock)(RCRequestBuilder *builder);
typedef void(^RCRequestCompletion)(RCResponse *response);

typedef NS_ENUM(NSUInteger, RCContentType)
{
    RCContentTypeApplicationJSON = 0,
    RCContentTypeFormURLEncoded = 1
};

NSString * StringFromRCContentType(RCContentType  contentType);

typedef NS_OPTIONS(NSInteger, RCRequestMethod) {
    RCRequestMethodGET = 1 << 0,
    RCRequestMethodPOST = 1 << 1,
    RCRequestMethodPUT  = 1 << 2,
    RCRequestMethodDELETE = 1 << 3,
    RCRequestMethodHEAD = 1 << 4,
    RCRequestMethodPATCH = 1 << 5,
    RCRequestMethodOPTIONS = 1 << 6,
    RCRequestMethodAny = (RCRequestMethodGET | RCRequestMethodPOST | RCRequestMethodPUT | RCRequestMethodDELETE | RCRequestMethodHEAD | RCRequestMethodPATCH | RCRequestMethodOPTIONS)
};

NSString * StringFromRCRequestMethod(RCRequestMethod requestMethod);
RCRequestMethod RCRequestMethodFromString(NSString *requestMethod);

typedef NS_ENUM(NSUInteger, RCStatusCodeClass)
{
    RCStatusCodeClassInformational = 100,
    RCStatusCodeClassSuccessful = 200,
    RCStatusCodeClassRedirection = 300,
    RCStatusCodeClassClientError = 400,
    RCStatusCodeClassServerError = 500
};

extern NSUInteger const RCStatusCodeClassRangeLength;

typedef NS_ENUM(NSUInteger, RCError)
{
    RCErrorValidationFailed = 1,
    RCErrorRequestFailed = 2
};
