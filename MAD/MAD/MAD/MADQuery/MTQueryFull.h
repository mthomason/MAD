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

@class NSManagedObjectID;

@interface MTQueryFull : MTQuery

    - (instancetype)initWithQueryObjectId:(NSManagedObjectID *)objectID andQueryLimit:(NSInteger)queryLimit;
    - (NSString *)getSqlWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError * __autoreleasing *)error;

    @property (nonatomic, assign) NSInteger limitResults;

@end

#endif
