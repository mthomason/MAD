//
//  MADQuerySelectExpressionActiveFields.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_MADQuerySelectExpressionActiveFields_h
#define Reports_MTQuery_MADQuerySelectExpressionActiveFields_h

#import "MADQuerySelectExpression.h"

@class RptqDatabaseSchemaField, NSString,
       NSMutableDictionary<KeyType, ObjectType>, NSMutableArray<ObjectType>;

@interface MADQuerySelectExpressionActiveFields : MADQuerySelectExpression

    - (instancetype)initWithDatabase:(MTDatabase *)database
             forManagedObjectContext:(NSManagedObjectContext *)context;

    @property (nonatomic, readonly, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readonly, strong) NSMutableArray <NSString *> *fieldKeys;

@end

#endif
