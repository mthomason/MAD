//
//  MADQuerySelectPart.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQuerySelectExpression.h"
#import "MADQuerySelectExpressionAllFields.h"
#import "MADQuerySelectExpressionActiveFields.h"

#import <CoreData/NSManagedObjectContext.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField+CoreDataClass.h"
#import "MTDatabase.h"

@implementation MADQuerySelectExpression

- (instancetype)initWithDatabase:(MTDatabase *)database
                          tables:(NSArray <MTPair *> *)tables
           usingOnlyActiveFields:(BOOL)onlyActiveFields
         forManagedObjectContext:(NSManagedObjectContext *)context {

    id result;
    if (onlyActiveFields) {
        
        result = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:database
                                                        forManagedObjectContext:context];
        
    } else {
        
        result = [[MADQuerySelectExpressionAllFields alloc] initWithDatabase:database
                                                                      tables:tables
                                                     forManagedObjectContext:context];
    }
    return result;
}

@end
