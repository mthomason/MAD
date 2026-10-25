//
//  MADQuerySelectExpressionActiveFields.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQuerySelectExpressionActiveFields.h"
#import <MAD/RptqStoreContext.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import <MADFoundation/MADStringUtilities.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import <MADAPI/MADDatabase.h>
#import <Foundation/NSString.h>

@interface MADQuerySelectExpressionActiveFields ()

    @property (nonatomic, readwrite, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSString *> *fieldKeys;

@end

// The column alias a field is written as: "Table0"."Field".
static NSString *MADActiveFieldAlias(MADDatabase *database, RptqQueryField *queryField) {
	NSString *tableName = [queryField.inQueryTable queryAlias];
	MADSafeQueryField *safeTableName = [database newSafeIdentifier: tableName];
	NSString *tableAlias = [MADStringUtilities stringByAppendingPeriod: safeTableName];
	MADSafeQueryField *fieldName = [database newSafeIdentifier: queryField.databaseSchemaField.name];
	return [tableAlias stringByAppendingString: fieldName];
}

// The set's enumeration order is hash order, and hash order is not stable -- not
// across runs and not across platforms (docs/project/BUGS.md: "the SELECT list's order is set
// order").  The order is defined here instead, once, as the column alias the list is
// written in, so the generated SQL, the row cache and every export share it.
// -compare: rather than a localized comparison, because GNUstep's localized
// comparison is case-sensitive (Linux/README.md) and this order must not be.
static NSArray <RptqQueryField *> *MADActiveFieldsInOrder(MADDatabase *database, NSSet <RptqQueryField *> *queryFields) {
	return [queryFields.allObjects sortedArrayUsingComparator: ^NSComparisonResult(RptqQueryField *a, RptqQueryField *b) {
		NSComparisonResult ordered = [MADActiveFieldAlias(database, a) compare: MADActiveFieldAlias(database, b)];
		// Two query fields can name one schema field and so share an alias; the
		// identifier is the document's own order and keeps the sort total.
		return ordered != NSOrderedSame ? ordered : [@(a.identifier) compare: @(b.identifier)];
	}];
}

@implementation MADQuerySelectExpressionActiveFields

- (instancetype)initWithDatabase:(MADDatabase *)database
         forManagedObjectContext:(RptqStoreContext *)context {

    if (self = [super init]) {
        
        NSMutableString *result = [[NSMutableString alloc] init];
        MADQueryActiveQueryFields *activeQueryFields;
        activeQueryFields = [[MADQueryActiveQueryFields alloc] initWithContext:context];

        NSArray <RptqQueryField *> *rptqQueryFields = MADActiveFieldsInOrder(database, activeQueryFields.queryFields);
        NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
        NSMutableArray <NSString *> *fieldKeys;

        fields = [[NSMutableDictionary alloc] initWithCapacity:rptqQueryFields.count];
        fieldKeys = [[NSMutableArray alloc] initWithCapacity:rptqQueryFields.count];

        NSUInteger fieldCounter = 0;
        for (RptqQueryField *queryField in rptqQueryFields) {

            RptqDatabaseSchemaField *field = queryField.databaseSchemaField;
            if (fieldCounter != 0)  [result appendString:@",\n"];

            NSString *fieldAlias = MADActiveFieldAlias(database, queryField);
            [result appendString: @"\t"];
            [result appendString: fieldAlias];

            fields[fieldAlias] = field;
            [fieldKeys addObject:fieldAlias];

            fieldCounter++;
        }
        if (fieldCounter > 0) {
            self.sql = result;
        }
        self.fields = fields;
        self.fieldKeys = fieldKeys;
        
    }
    return self;
}

@end

