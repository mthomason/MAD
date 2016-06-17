//
//  MADQuerySelectExpressionAllFields.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_MADQuerySelectExpressionAllFields_h
#define Reports_MTQuery_MADQuerySelectExpressionAllFields_h

#import "MADQuerySelectExpression.h"

@class MTDatabase;
@class NSManagedObjectContext;
@class MTPair;

@interface MADQuerySelectExpressionAllFields : MADQuerySelectExpression

    - (instancetype)initWithDatabase:(MTDatabase *)database
                              tables:(NSArray <MTPair *> *)tables
             forManagedObjectContext:(NSManagedObjectContext *)context;

@end

#endif
