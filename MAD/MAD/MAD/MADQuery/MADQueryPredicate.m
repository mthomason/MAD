//
//  MADQueryPredicate.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryPredicate.h"
#import <Foundation/NSString.h>

#import <MADFoundation/MADDataType.h>

#import "MTDatabase.h"
#import "MADDatabaseField.h"

#import "RptqQueryTable.h"
#import "RptqQueryField.h"

#import "RptqQueryPredicate.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqQueryTable+Extras.h"
#import "RptqQueryPredicate+Extras.h"


@interface MADQueryPredicate ()

    @property (nonatomic, readwrite, strong) NSString *sql;

@end

@implementation MADQueryPredicate

- (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                            andDatabase:(MTDatabase *)database {
    if (self = [super init]) {
        
        NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
        NSUInteger loopCounter = 0;
        
        for (RptqQueryPredicate *queryPredicate in queryPredicates) {
            
            if (loopCounter == 0) {
                [result appendString:@"\nWHERE\n"];
            } else {
                [result appendString:@" AND \n"];
            }
            
            NSString *leftValue = nil;
            
            if (queryPredicate.hasLeftField != nil) {
                
                RptqQueryField *leftField = queryPredicate.hasLeftField;
                NSString *leftTableName = [leftField.inQueryTable queryAlias];
                
                leftValue = [database newSafeQueryField: leftField.databaseSchemaField.name
                                               andTable: leftTableName];
                
            } else if (queryPredicate.leftFieldID != nil) {
                
                leftValue = queryPredicate.leftFieldID;
                
            }
            
            NSString *rightValue = nil;
            
            if (queryPredicate.hasRightField != nil) {
                
                RptqQueryField *rightField = queryPredicate.hasRightField;
                NSString *rightTableName = [rightField.inQueryTable queryAlias];
                rightValue = [database newSafeQueryField: rightField.databaseSchemaField.name
                                                andTable: rightTableName];
                
            } else if (queryPredicate.rightFieldID != nil) {
                
                RptqQueryField *leftField = queryPredicate.hasLeftField;
                MADDataType dataType = leftField.databaseSchemaField.dataType;
                
                NSString *rightFieldID = queryPredicate.rightFieldID;
                rightValue = [MADDatabaseField isNumeric:dataType] ? rightFieldID :
                [[NSString alloc] initWithFormat: @"\"%@\"", rightFieldID];
            }
            NSString *symbolForComparson = [queryPredicate symbolForComparson];
            [result appendFormat:@"\t(%@ %@ %@)", leftValue, symbolForComparson, rightValue];
            
            loopCounter++;
        }
        self.sql = result;
        
    }
    return self;
}

@end
