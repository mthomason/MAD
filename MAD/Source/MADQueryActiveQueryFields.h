//
//  MADQueryActiveQueryFields.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryActiveQueryFields_h
#define Reports_MADQueryActiveQueryFields_h

#import <Foundation/NSObject.h>
#import <MAD/RptqStoreContext.h>

@class RptqQuery, RptqQueryField, NSSet <__covariant ObjectType>;

// This class returns every query field some report element, link or group
// references.  Pass a query to scope the result to the fields whose query table
// belongs to that query -- the report may hold more than one query, and a field
// referenced only by another query must not enter this query's SELECT list.

@interface MADQueryActiveQueryFields : NSObject

- (instancetype)initWithContext:(RptqStoreContext *)context;

/// @param query The query whose fields to collect, or nil for the whole context.
- (instancetype)initWithContext:(RptqStoreContext *)context query:(nullable RptqQuery *)query;

@property (nonatomic, strong) NSSet <RptqQueryField *> *queryFields;

@end

#endif
