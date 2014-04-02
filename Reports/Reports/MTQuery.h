//
//  MTQuery.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_h
#define Reports_MTQuery_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTQueryType) {
	MTQueryTypeMaxFieldLength,
};

extern NSString * const MTQueryKeyType;
extern NSString * const MTQueryKeyObject;

@class RptqQuery, RptqDatabase, RptqDocument, RptqQueryField, MTDatabase, RptqQueryCache,
        RptqDatabaseSchemaTable, RptqDatabaseSchemaField,
        MTDatabaseConnection, MTCache;

@interface MTQuery : NSObject

@property (nonatomic, strong, readonly) MTDatabase *database;
@property (nonatomic, strong, readonly) MTDatabaseConnection *credentials;
@property (nonatomic, strong) MTCache *cache;
@property (nonatomic, strong) id queryObject;
@property (nonatomic, strong) NSMutableDictionary *fields;
@property (nonatomic, strong) NSMutableArray *fieldKeys;

- (id)initWithObject:(id)object;
+ (id)queryFactory:(id)object;



- (NSString *)getSqlWithError:(NSError **)error;
- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error;

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion;

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only

- (NSArray *)sortedHasQueryGroups;
- (NSArray *)sortDescriptors;

- (NSString *)fieldKeyForIndex:(NSUInteger)index;

@end

#endif
