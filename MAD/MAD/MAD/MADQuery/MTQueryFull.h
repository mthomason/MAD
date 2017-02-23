//
//  MTQueryReport.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryFull_h
#define Reports_MTQueryFull_h

#import "MTQuery.h"

@class NSManagedObjectID, NSManagedObjectContext;

@interface MTQueryFull : MTQuery

    - (instancetype)initWithQuery:(RptqQuery *)query andQueryLimit:(NSUInteger)queryLimit;

    - (NSString *)copySQLWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                            error:(NSError * __autoreleasing *)error;

    - (NSString *)SQLOnlyActiveFields:(BOOL)onlyActiveFields
                 managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                error:(NSError **)error;

    @property (nonatomic, assign) NSUInteger limitResults;

@end

#endif
