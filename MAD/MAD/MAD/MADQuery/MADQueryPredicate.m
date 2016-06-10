//
//  MADQueryPredicate.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryPredicate.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "MTDatabase.h"
#import "MTDatabaseField.h"
#import <MADFoundation/MADDataType.h>

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
                NSString *leftTableName = [leftField.inQueryTable copyQueryAlias];
                
                leftValue = [database newSafeQueryField: leftField.databaseSchemaField.name
                                               andTable: leftTableName];
                
            } else if (queryPredicate.fieldleftpred != nil) {
                
                leftValue = queryPredicate.fieldleftpred;
                
            }
            
            NSString *rightValue = nil;
            
            if (queryPredicate.hasRightField != nil) {
                
                RptqQueryField *rightField = queryPredicate.hasRightField;
                NSString *rightTableName = [rightField.inQueryTable copyQueryAlias];
                rightValue = [database newSafeQueryField: rightField.databaseSchemaField.name
                                                andTable: rightTableName];
                
            } else if (queryPredicate.fieldrightpred != nil) {
                
                RptqQueryField *leftField = queryPredicate.hasLeftField;
                MADDataType dataType = leftField.databaseSchemaField.dataType.shortValue;
                
                NSString *fieldrightpred = queryPredicate.fieldrightpred;
                rightValue = [MTDatabaseField isNumeric:dataType] ? fieldrightpred :
                [[NSString alloc] initWithFormat: @"\"%@\"", fieldrightpred];
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
