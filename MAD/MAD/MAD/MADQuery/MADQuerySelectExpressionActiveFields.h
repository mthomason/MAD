//
//  MADQuerySelectExpressionActiveFields.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADQuerySelectExpression.h"

@class MTDatabase;
@class NSManagedObjectContext;
@class RptqDatabaseSchemaField;

@interface MADQuerySelectExpressionActiveFields : MADQuerySelectExpression

    - (instancetype)initWithDatabase:(MTDatabase *)database
             forManagedObjectContext:(NSManagedObjectContext *)context;

    @property (nonatomic, readonly, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readonly, strong) NSMutableArray <NSString *> *fieldKeys;


@end
