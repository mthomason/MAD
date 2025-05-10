//
//  MADQuerySelectPart.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQuerySelectExpression.h"
#import "MADQuerySelectExpressionAllFields.h"
#import "MADQuerySelectExpressionActiveFields.h"

#import <CoreData/NSManagedObjectContext.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import <MADAPI/MADDatabase.h>

@implementation MADQuerySelectExpression

- (instancetype)initWithDatabase:(MADDatabase *)database
						  tables:(NSArray <MTPair *> *)tables
		   usingOnlyActiveFields:(BOOL)onlyActiveFields
		 forManagedObjectContext:(NSManagedObjectContext *)context {

	__kindof MADQuerySelectExpression *result = onlyActiveFields ?
		[[MADQuerySelectExpressionActiveFields alloc] initWithDatabase:database forManagedObjectContext:context]:
		[[MADQuerySelectExpressionAllFields alloc] initWithDatabase:database tables:tables forManagedObjectContext:context];
	return result;
}

@end
