//
//  MADQueryPredicate.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryPredicate.h"
#import <Foundation/NSString.h>

#import <MADFoundation/MADDataType.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

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
                            andDatabase:(MADDatabase *)database {
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
                
                leftValue = [database queryKey: leftField.databaseSchemaField.name table: leftTableName];
                
            } else if (queryPredicate.leftFieldID != nil) {
                
                leftValue = queryPredicate.leftFieldID;
                
            }
            
            NSString *rightValue = nil;
            
            if (queryPredicate.hasRightField != nil) {
                
                RptqQueryField *rightField = queryPredicate.hasRightField;
                NSString *rightTableName = [rightField.inQueryTable queryAlias];
                rightValue = [database queryKey: rightField.databaseSchemaField.name table: rightTableName];
                
            } else if (queryPredicate.rightFieldID != nil) {
                
                RptqQueryField *leftField = queryPredicate.hasLeftField;
                MADDataType dataType = leftField.databaseSchemaField.dataType;
                
                // Despite the name, -rightFieldID holds the user's typed value, not an id.
                // A number is already a valid SQL literal; anything else has to be quoted
                // and escaped the way the database in use reads, which is what
                // -newSafeLiteral: is for.  It used to be @"\"%@\"" -- a double quote, which
                // SQL reads as a *name*: the filter read as a reference to a column called
                // London.  See BUGS.md.
                NSString *rightFieldID = queryPredicate.rightFieldID;
                rightValue = [MADDatabaseField isNumeric:dataType] ? rightFieldID :
                [database newSafeLiteral: rightFieldID];
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
