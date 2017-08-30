//
//  MTQueryReport.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryFull_h
#define Reports_MTQueryFull_h

#import <MADAPI/MTQuery.h>

@class NSManagedObjectID, NSManagedObjectContext, RptqQuery;

@interface MTQueryFull : MTQuery
    <MADQueryFieldKeysProtocol, MADQueryDataDelegateProtocol>
    - (instancetype)initWithQuery:(RptqQuery *)query andQueryLimit:(NSUInteger)queryLimit;

    - (NSString *)copySQLWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                            error:(NSError * __autoreleasing *)error;

    - (NSString *)SQLOnlyActiveFields:(BOOL)onlyActiveFields
                 managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                error:(NSError **)error;

    @property (nonatomic, assign) NSUInteger limitResults;

@end

#endif
