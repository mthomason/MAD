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

@class RptqDatabaseSchemaField, NSString,
       NSMutableDictionary, NSMutableArray<ObjectType>;

@interface MADQuerySelectExpressionActiveFields : MADQuerySelectExpression

    - (instancetype)initWithDatabase:(MADDatabase *)database
             forManagedObjectContext:(RptqStoreContext *)context;

    @property (nonatomic, readonly, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readonly, strong) NSMutableArray <NSString *> *fieldKeys;

@end

#endif
