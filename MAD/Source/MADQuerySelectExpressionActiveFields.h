//
//  MADQuerySelectExpressionActiveFields.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQuery_MADQuerySelectExpressionActiveFields_h
#define Reports_MTQuery_MADQuerySelectExpressionActiveFields_h

#import "MADQuerySelectExpression.h"
#import <MAD/RptqStoreContext.h>

@class RptqDatabaseSchemaField, RptqQuery, RptqQueryField, NSString, NSSet,
       NSMutableDictionary, NSMutableArray<ObjectType>;

@interface MADQuerySelectExpressionActiveFields : MADQuerySelectExpression

    - (instancetype)initWithDatabase:(MADDatabase *)database
             forManagedObjectContext:(RptqStoreContext *)context;

/// @param query The query whose active fields to project, or nil for every field
///              the context references (the legacy, unscoped form).
    - (instancetype)initWithDatabase:(MADDatabase *)database
                               query:(nullable RptqQuery *)query
             forManagedObjectContext:(RptqStoreContext *)context;

/// As above, but also projects `requiredFields` -- fields a downstream consumer
/// needs without a report element referencing them.
    - (instancetype)initWithDatabase:(MADDatabase *)database
                               query:(nullable RptqQuery *)query
             forManagedObjectContext:(RptqStoreContext *)context
                      requiredFields:(nullable NSSet <RptqQueryField *> *)requiredFields;

    @property (nonatomic, readonly, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readonly, strong) NSMutableArray <NSString *> *fieldKeys;

@end

#endif
