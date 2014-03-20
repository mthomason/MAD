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

@class RptqQuery, RptqDatabase, RptqDocument, RptqQueryField, MTDatabase, RptqQueryCache, RptqDatabaseSchemaField,
        MTDatabaseConnection;

@interface MTQuery : NSObject

@property (nonatomic, strong, readonly) MTDatabase *database;
@property (nonatomic, strong, readonly) MTDatabaseConnection *credentials;

- (id)initWithDatabase:(RptqDatabase *)database;
- (NSString *)selectPart;
- (NSString *)getSqlForQuery:(RptqQuery *)query error:(NSError **)error;
- (NSString *)getSqlForQuery:(RptqQuery *)query onlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error;

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(BOOL success, NSError *error, id results))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

+ (id)queryForRptqQuery:(RptqQuery *)rptqQuery;
+ (NSString *)safeQueryField:(RptqQueryField *)queryField;

@end

#endif
