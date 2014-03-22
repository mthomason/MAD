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

@class RptqQuery, RptqDatabase, RptqDocument, RptqQueryField, MTDatabase, RptqQueryCache,
        RptqDatabaseSchemaTable, RptqDatabaseSchemaField,
        MTDatabaseConnection, MTCache;

@interface MTQuery : NSObject

@property (nonatomic, strong, readonly) MTDatabase *database;
@property (nonatomic, strong, readonly) MTDatabaseConnection *credentials;
@property (nonatomic, strong) MTCache *cache;

- (id)initWithObject:(id)object;
+ (id)queryFactory:(id)object;

- (NSString *)getSqlWithError:(NSError **)error;
- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error;

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(BOOL success, NSError *error, id results))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only

- (NSString *)sqlLimitClause;

@end

#endif
