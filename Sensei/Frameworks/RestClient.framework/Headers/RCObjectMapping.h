//
//  RCObjectMapping.h
//  RestClient
//
//  Created by Sauron Black on 3/29/15.
//  Copyright (c) 2015 Totenkopf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCRelationshipMapping;

@protocol RCValueTransformerProtocol;

@interface RCObjectMapping : NSObject

@property (assign, nonatomic) Class objectClass;

+ (void)setDefaultDateFormat:(NSString *)dateFormat;

- (instancetype)initWithObjectClass:(Class)aClass mappingDictionary:(NSDictionary *)mappingDictionary;
- (instancetype)initWithObjectClass:(Class)aClass mappingArray:(NSArray *)keys;
- (instancetype)initWithObjectClass:(Class)aClass;

- (instancetype)inversMapping;

- (void)addPropertyMappingFromArray:(NSArray *)keys;
- (void)addPropertyMappingFromDictionary:(NSDictionary *)propertyMapping;
- (void)addRelationshipMapping:(RCRelationshipMapping *)relationshipMapping;
- (void)setValueTransformerClass:(Class<RCValueTransformerProtocol>)transformerClass forProperty:(NSString *)propertyName;

- (id)objectWithJSON:(NSDictionary *)json;
- (NSArray *)objectsWithJSONs:(NSArray *)jsons;

- (NSDictionary *)jsonWithObject:(id)object;
- (NSArray *)jsonsWithObjects:(NSArray *)objects;

@end

@protocol RCValueTransformerProtocol <NSObject>

+ (id)objectValueFromJSONValue:(NSString *)jsonValue;
+ (NSString *)JSONValueFromObjectValue:(id)objectValue;

@end